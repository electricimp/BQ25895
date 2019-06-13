// MIT License
//
// Copyright 2018-19 Electric Imp
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

//Registers Addresses
const BQ25895_REG00 = 0x00;
const BQ25895_REG01 = 0x01;
const BQ25895_REG02 = 0x02;
const BQ25895_REG03 = 0x03;
const BQ25895_REG04 = 0x04;
const BQ25895_REG05 = 0x05;
const BQ25895_REG06 = 0x06;
const BQ25895_REG07 = 0x07;
const BQ25895_REG08 = 0x08;
const BQ25895_REG09 = 0x09;
const BQ25895_REG0A = 0x0A;
const BQ25895_REG0B = 0x0B;
const BQ25895_REG0C = 0x0C;
const BQ25895_REG0D = 0x0D;
const BQ25895_REG0E = 0x0E;
const BQ25895_REG0F = 0x0F;
const BQ25895_REG10 = 0x10;
const BQ25895_REG11 = 0x11;
const BQ25895_REG12 = 0x12;
const BQ25895_REG13 = 0x13;
const BQ25895_REG14 = 0x14;

// For vbusStatus in getInputStatus() output
enum BQ25895_VBUS_STATUS {
    NO_INPUT             = 0x00, // 0 
    USB_HOST_SDP         = 0x20, // 1
    USB_CDP              = 0x40, // 2
    USB_DCP              = 0x60, // 3
    ADJUSTABLE_HV_DCP    = 0x80, // 4
    UNKNOWN_ADAPTER      = 0xA0, // 5
    NON_STANDARD_ADAPTER = 0xC0, // 6
    OTG                  = 0xE0  // 7
}

// For getChargeStatus() output
enum BQ25895_CHARGING_STATUS {
    NOT_CHARGING            = 0x00, // 0
    PRE_CHARGE              = 0x08, // 1
    FAST_CHARGING           = 0x10, // 2
    CHARGE_TERMINATION_DONE = 0x18  // 3
}

// For CHGR_FAULT in getChargingFaults() output
enum BQ25895_CHARGING_FAULT {
    NORMAL                         = 0x00,
    INPUT_FAULT                    = 0x10,
    THERMAL_SHUTDOWN               = 0x20, 
    CHARGE_SAFETY_TIMER_EXPIRATION = 0x30
}

// For NTC_FAULT in getChargingFaults() output
enum BQ25895_NTC_FAULT {
    NORMAL,  // 0
    TS_COLD, // 1
    TS_HOT   // 2
}

enum BQ25895_DEFAULT_SETTINGS {
    CRG_VOLTAGE    = 4.208,
    REG02_DEFAULTS = 0x3D
}

enum BQ25895M_DEFAULT_SETTINGS {
    CRG_VOLTAGE    = 4.352,
    REG02_DEFAULTS = 0x31
}

enum BQ25895_M_SHARED_DEFAULTS {
    CRG_CURR         = 2048, 
    REG03_DEFAULT    = 0x3A,
    CHARGE_TERM_CURR = 256
}

class BQ25895 {

    static VERSION = "2.0.0";

    // I2C information
    _i2c = null;
    _addr = null;

    constructor(i2c, addr = 0xD4) {
        _i2c = i2c;
        _addr = addr;
    }

    // Initialize battery charger
    function enable(settings = {}) {
        // Set to default BQ25895M settings
        local voltage = BQ25895_DEFAULT_SETTINGS.CRG_VOLTAGE;
        local current = BQ25895_M_SHARED_DEFAULTS.CRG_CURR;

        if ("BQ25895MDefaults" in settings && settings.BQ25895MDefaults) {
            voltage = BQ25895M_DEFAULT_SETTINGS.CRG_VOLTAGE;
            current = BQ25895_M_SHARED_DEFAULTS.CRG_CURR;
            // Set High Voltage DCP and Max Charge Adapter settings
            _setReg(BQ25895_REG02, BQ25895M_DEFAULT_SETTINGS.REG02_DEFAULTS);
        } else {
            if ("voltage" in settings) voltage = settings.voltage;
            if ("current" in settings) current = settings.current;
            _setReg(BQ25895_REG02, BQ25895_DEFAULT_SETTINGS.REG02_DEFAULTS);
        }

        // Disable Watchdog, so settings remain even through sleep cycles
        _disableWatchdog();

        // Enable charger and min system voltage
        _setReg(BQ25895_REG03, BQ25895_M_SHARED_DEFAULTS.REG03_DEFAULT);

        // Update settings
        _setChargeVoltage(voltage);
        _setChargeCurrent(current);

        if (("setChargeCurrentOptimizer" in settings) && settings.setChargeCurrentOptimizer) {
            // Enable charge current optimizer
            _setRegBit(BQ25895_REG09, 7, 1); 
        } else {
            // Disable charge current optimizer
            _setRegBit(BQ25895_REG09, 7, 0); 
        }
    
        if ("setChargeTerminationCurrentLimit" in settings) {
            _setChargeTerminationCurrent(settings.setChargeTerminationCurrentLimit);        
        } else {
            // Set default charge termination current limit of 256mA
            _setChargeTerminationCurrent(BQ25895_M_SHARED_DEFAULTS.CHARGE_TERM_CURR); 
        }
    }

    // Clear the enable charging bit, device will not charge until enableCharging() is called again
    function disable() {
        // Disable Watchdog, to keep charger disabled setting even through sleep cycles
        _disableWatchdog();

        local rd = _getReg(BQ25895_REG03);

        // Clear CHG_CONFIG bits
        rd = rd & ~(1 << 4); 
        _setReg(BQ25895_REG03, rd);
    }

    // Returns the target battery voltage
    function getChargeVoltage() {
        local rd = _getReg(BQ25895_REG06);

        // 16mV is the resolution, 3840mV must be added as the offset
        local chrgVlim = ((rd >> 2) * 16) + 3840; 
        // Convert mV to Volts
        return chrgVlim / 1000.0;
    }

    // Returns the battery voltage based on the ADC conversion
    function getBatteryVoltage() {
        // Kick ADC
        _convStart(); 
        local rd = _getReg(BQ25895_REG0E);

        // 2304mV must be added as the offset, 20mV is the resolution
        local battV = (2304 + (20 * (rd & 0x7f))); 
        // Convert mV to Volts
        return battV / 1000.0;
    }

    // Returns the VBUS voltage based on the ADC conversion, this is the input voltage
    function getVBUSVoltage() {
        // Kick ADC
        _convStart(); 
        local rd = _getReg(BQ25895_REG11);

        // 2600mV must be added as the offset, 100mV is the resolution
        local vBusV = (2600 + (100 * (rd & 0x7f))) 
        // Convert mV to Volts
        return vBusV / 1000.0;
    }

    // Returns the system voltage based on the ADC conversion
    function getSystemVoltage() {
        // Kick ADC
        _convStart(); 
        local rd = _getReg(BQ25895_REG0F);

        // 2304mV must be added as the offset, 20mV is the resolution
        local sysV = (2304 + (20 * (rd & 0x7f))); 
        return sysV / 1000.0;
    }
    
    // Returns the charging mode and input current limit in a table
    function getInputStatus(){
        local inputStatus = {
            "vbusStatus"        : 0, 
            "inputCurrentLimit" : 0
        };

        // Read VBUS status reg
        local rd = _getReg(BQ25895_REG0B); 
        inputStatus.vbusStatus <- rd & 0xE0;
        
        // Read input current limit reg
        rd = _getReg(BQ25895_REG00);
        // 100mA offset, 50mA resolution
        inputStatus.inputCurrentLimit <- (100 + (50 * (rd & 0x3f))); 
        
        return inputStatus;
    }

    // Returns the measured charge current based on the ADC conversion
    function getChargingCurrent() {
        // Kick ADC
        _convStart(); 
        local rd = _getReg(BQ25895_REG12);

        // 50mA is the resolution
        local iChgr = (50 * (rd & 0x7f)); 
        return iChgr;
    }

    // Returns the charging status: Not Charging, Pre-charge, Fast Charging, Charge Termination Good
    function getChargingStatus() {
        local rd = _getReg(BQ25895_REG0B);
        return rd & 0x18;
    }

    // Returns the possible charger faults in an array: watchdogFault, boostFault, chrgFault, battFault, ntcFault
    function getChargerFaults() {
        local chargerFaults = {
            "watchdogFault" : 0, 
            "boostFault"    : 0, 
            "chrgFault"     : 0, 
            "battFault"     : 0, 
            "ntcFault"      : 0
        };

        local rd = _getReg(BQ25895_REG0C);
        chargerFaults.watchdogFault <- (rd & 0x80) == 0x80;
        chargerFaults.boostFault <- (rd & 0x40) == 0x40;
        // Normal, input fault, thermal shutdown, charge safety timer expiration
        chargerFaults.chrgFault <- rd & 0x30; 
        chargerFaults.battFault <- (rd & 0x08) == 0x08;
        // Normal, TS cold, TS hot 
        // For compatibility between BQ25895 & BQ25895M drop the top bit, it is not needed to determine NTC fault
        chargerFaults.ntcFault <- rd & 0x03; 

        return chargerFaults;
    }

    // Restore default device settings
    function reset() {
        // Set reset bit
        _setRegBit(BQ25895_REG14, 7, 1);
        imp.sleep(0.01);
        // Clear reset bit
        _setRegBit(BQ25895_REG14, 7, 0);
    }

    //-------------------- PRIVATE METHODS --------------------//

    // Set target battery voltage
    function _setChargeVoltage(vreg) {
        // Convert to mV
        vreg *= 1000;

        // Check that input is within accepted range
        if (vreg < 3840) {
            // minimum charge voltage from device datasheet
            vreg = 3840;
        } else if (vreg > 4608) {
            // maximum charge voltage from device datasheet
            vreg = 4608;
        }

        local rd = _getReg(BQ25895_REG06);
        // Clear bits
        rd = rd & ~(0xFC); 
        // 3840mV is the default offset, 16mV is the resolution
        rd = rd | (0xFC & (((vreg - 3840) / 16).tointeger()) << 2); 

        _setReg(BQ25895_REG06, rd);
    }

    // Set fast charge current
    function _setChargeCurrent(ichg) {
        // Check that input is within accepted range
        if (ichg < 0) { 
            // Charge current must be greater than 0
            ichg = 0;
        } else if (ichg > 5056) { 
            // Max charge current from device datasheet
            ichg = 5056;
        }

        local rd = _getReg(BQ25895_REG04);
        // Clear bits
        rd = rd & ~(0x7F); 
        // 64mA is the resolution
        rd = rd | (0x7F & ichg / 64); 

        _setReg(BQ25895_REG04, rd);
    }
    
    function _setChargeTerminationCurrent(iterm){
        // Check that input is within accepted range
        if (iterm < 64) { 
            // charge current must be greater than 0
            iterm = 64;
        } else if (iterm > 1024) { 
            // max charge current from device datasheet
            iterm = 1024;
        }

        local rd = _getReg(BQ25895_REG05);
        // clear bits
        rd = rd & ~(0x0F); 
        // 64mA is the resolution
        rd = rd | (0x0F & (iterm - 64) / 64); 

        _setReg(BQ25895_REG05, rd); 
    }

    function _disableWatchdog() {
        _setRegBit(BQ25895_REG07, 5, 0);
        _setRegBit(BQ25895_REG07, 4, 0);
    }

    function _convStart() {
        // call before ADC conversion
        _setRegBit(BQ25895_REG02, 7, 1);
    }

    function _getReg(reg) {
        local result = _i2c.read(_addr, reg.tochar(), 1);
        if (result == null) {
            throw "I2C read error: " + _i2c.readerror();
        }
        return result[0];
    }

    function _setReg(reg, val) {
        local result = _i2c.write(_addr, format("%c%c", reg, (val & 0xff)));
        if (result) {
            throw "I2C write error: " + result;
        }
        return result;
    }

    function _setRegBit(reg, bit, state) {
        local val = _getReg(reg);
        if (state == 0) {
            val = val & ~(0x01 << bit);
        } else {
            val = val | (0x01 << bit);
        }
        return _setReg(reg, val);
    }

}