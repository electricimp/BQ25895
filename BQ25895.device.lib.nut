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

// Registers Addresses
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

// ADC Conversion timings
// NOTE: ADC conversion time nominal 8ms, max 1s, imp.wakeup min is ~0.01
const BQ25895_CONV_CHECK_SEC   = 0.01;  
const BQ25895_CONV_TIMEOUT_SEC = 1;    

const BQ25895_DEFAULT_I2C_ADDR = 0xD4;

// For vbusStatus in getInputStatus() output
enum BQ25895_VBUS_STATUS {
    NO_INPUT             = 0x00, 
    USB_HOST_SDP         = 0x20, 
    USB_CDP              = 0x40, 
    USB_DCP              = 0x60, 
    ADJUSTABLE_HV_DCP    = 0x80, 
    UNKNOWN_ADAPTER      = 0xA0, 
    NON_STANDARD_ADAPTER = 0xC0, 
    OTG                  = 0xE0  
}

// For getChrgStatus() output
enum BQ25895_CHARGING_STATUS {
    NOT_CHARGING            = 0x00, 
    PRE_CHARGE              = 0x08, 
    FAST_CHARGING           = 0x10, 
    CHARGE_TERMINATION_DONE = 0x18  
}

// For CHGR_FAULT in getChrgFaults() output
enum BQ25895_CHARGING_FAULT {
    NORMAL                         = 0x00,
    INPUT_FAULT                    = 0x10,
    THERMAL_SHUTDOWN               = 0x20, 
    CHARGE_SAFETY_TIMER_EXPIRATION = 0x30
}

// For NTC_FAULT in getChrgFaults() output
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

    static VERSION = "3.0.0";

    // I2C information
    _i2c         = null;
    _addr        = null;

    // ADC conversion vars
    _convCbs     = null;
    _convStarted = null;
    _convTmr     = null;
    _convTimeout = null;

    constructor(i2c, addr = BQ25895_DEFAULT_I2C_ADDR) {
        _i2c = i2c;
        _addr = addr;
        _convStarted = false;
        _convCbs = [];
    }

    // Initialize battery charger
    function enable(settings = {}) {
        // Set to default BQ25895M settings
        local volt = BQ25895_DEFAULT_SETTINGS.CRG_VOLTAGE;
        local curr = BQ25895_M_SHARED_DEFAULTS.CRG_CURR;

        if ("BQ25895MDefaults" in settings && settings.BQ25895MDefaults) {
            volt = BQ25895M_DEFAULT_SETTINGS.CRG_VOLTAGE;
            curr = BQ25895_M_SHARED_DEFAULTS.CRG_CURR;
            // Set High Voltage DCP and Max Charge Adapter settings
            _setReg(BQ25895_REG02, BQ25895M_DEFAULT_SETTINGS.REG02_DEFAULTS);
        } else {
            if ("voltage" in settings) volt = settings.voltage;
            if ("current" in settings) curr = settings.current;
            _setReg(BQ25895_REG02, BQ25895_DEFAULT_SETTINGS.REG02_DEFAULTS);
        }

        // Disable Watchdog, so settings remain even through sleep cycles
        _disableWatchdog();

        // Enable charger and min system voltage
        _setReg(BQ25895_REG03, BQ25895_M_SHARED_DEFAULTS.REG03_DEFAULT);

        // Update settings
        _setChrgV(volt);
        _setChrgCurr(curr);

        if (("forceICO" in settings) && settings.forceICO) {
            // Enable force start input charge current optimizer
            _setRegBit(BQ25895_REG09, 7, 1); 
        } else {
            // Disable force start input charge current optimizer
            _setRegBit(BQ25895_REG09, 7, 0); 
        }
    
        if ("chrgTermLimit" in settings) {
            _setChrgTermCurr(settings.chrgTermLimit);        
        } else {
            // Set default charge termination current limit of 256mA
            _setChrgTermCurr(BQ25895_M_SHARED_DEFAULTS.CHARGE_TERM_CURR); 
        }
    }

    // Clear the enable charging bit, device will not charge until enableCharging() is called again
    function disable() {
        // Disable Watchdog, to keep charger disabled setting even through sleep cycles
        _disableWatchdog();

        // Clear CHG_CONFIG bit
        _setRegBit(BQ25895_REG03, 4, 0);
    }

    // Returns the target battery voltage
    function getChrgTermV() {
        local rd = _getReg(BQ25895_REG06);

        // 16mV is the resolution, 3840mV must be added as the offset
        local chrgVlim = ((rd >> 2) * 16) + 3840; 
        // Convert mV to Volts
        return chrgVlim / 1000.0;
    }

    // Returns the charging mode and input current limit in a table
    function getInputStatus(){
        // Read VBUS status reg
        local vbus_rd = _getReg(BQ25895_REG0B); 
        
        // Read input current limit reg
        local incurr_rd = _getReg(BQ25895_REG00);
        // 100mA offset, 50mA resolution
        incurr_rd = ((incurr_rd & 0x3f) * 50) + 100;
        
        return {
            "vbus"      : vbus_rd & 0xE0, 
            "currLimit" : incurr_rd
        };
    }

    // Returns the charging status: Not Charging, Pre-charge, Fast Charging, Charge Termination Good
    function getChrgStatus() {
        local rd = _getReg(BQ25895_REG0B);
        return rd & 0x18;
    }

    // Returns the possible charger faults in an array: watchdogFault, boostFault, chrgFault, battFault, ntcFault
    function getChrgFaults() {
        // Read faults register
        local rd = _getReg(BQ25895_REG0C);
        return {
            "watchdog" : (rd & 0x80) == 0x80, 
            "boost"    : (rd & 0x40) == 0x40, 
            "chrg"     : rd & 0x30,            // Normal, input fault, thermal shutdown, charge safety timer expiration
            "batt"     : (rd & 0x08) == 0x08, 
            "ntc"      : rd & 0x03             // Normal, TS cold, TS hot, For compatibility between BQ25895 & BQ25895M drop the top bit, it is not needed to determine NTC fault
        };
    }

    // Passes the battery voltage based on the ADC conversion to the callback, may take up to 
    // 1s to get a value
    function getBattV(cb) {
        // Create and add a get battery voltage callback to _convCbs
        // Register: BQ25895_REG0E, Register Bit Mask: 0x7F, Offset: 2304mV, Convert mV to V, Resolution: 20mV
        _convCbs.push(_convCbFactory(BQ25895_REG0E, 0x7F, 2304, 20, true, cb));

        // Start ADC conversion
        _convStart();
    }

    // Passes the VBUS (input) voltage based on the ADC conversion to the callback, may take up to 
    // 1s to get a value
    function getVBUSV(cb) {
        // Create and add a get VBUS voltage callback to _convCbs
        // Register: BQ25895_REG11, Register Bit Mask: 0x7F, Offset: 2600mV, Convert mV to V, Resolution: 100mV
        _convCbs.push(_convCbFactory(BQ25895_REG11, 0x7F, 2600, 100, true, cb));

        // Start ADC conversion
        _convStart();
    }

    // Passes the system voltage based on the ADC conversion to the callback, may take up to 
    // 1s to get a value
    function getSysV(cb) {
        // Create and add a get system voltage callback to _convCbs
        // Register: BQ25895_REG0F, Register Bit Mask: 0x7F, Offset: 2304mV, Convert mV to V, Resolution: 20mV
        _convCbs.push(_convCbFactory(BQ25895_REG0F, 0x7F, 2304, 20, true, cb));

        // Start ADC conversion
        _convStart();
    }
    
    // Passes the measured charge current based on the ADC conversion to the callback, may take up to 
    // 1s to get a value
    function getChrgCurr(cb ) {
        // Create and add a get charging current callback to _convCbs
        // Register: BQ25895_REG12, Register Bit Mask: 0x7F, Offset: 0, Convert mA to A, Resolution: 50mV
        _convCbs.push(_convCbFactory(BQ25895_REG12, 0x7F, 0, 50, false, cb));

        // Start ADC conversion
        _convStart();
    }

    // Restore default device settings
    function reset() {
        // Set reset bit
        _setRegBit(BQ25895_REG14, 7, 1);
        imp.sleep(0.01);
        // Clear reset bit
        _setRegBit(BQ25895_REG14, 7, 0);
    }

    // PRIVATE METHODS
    // --------------------------------------------------------

    // Set target battery voltage
    function _setChrgV(vreg) {
        // Convert to V to mV, ensure value is within range 3504mV and 4400mV
        // and calculate value with offset: 3.840V and resolution: 16mV 
        vreg = (_limit(vreg * 1000, 3840, 4608) - 3840) / 16;

        // Get current register value
        local rd = _getReg(BQ25895_REG06);
        // Clear Charge Voltage Limit (VREG) bits
        rd = rd & ~(0xFC); 

        // Update register value with new VREG value
        rd = rd | ((vreg.tointeger() << 2) & 0xFC);
        _setReg(BQ25895_REG06, rd);
    }

    // Set fast charge current
    function _setChrgCurr(ichg) {
        // Ensure value is within range 0mA and 5056mA and calculate
        // value with resolution: 64mA         
        ichg = _limit(ichg, 0, 5056) / 64;

        // Get current register value
        local rd = _getReg(BQ25895_REG04);
        // Clear Charge Current Limit (ICHG) bits
        rd = rd & ~(0x7F); 

        // Update register value with new current (ICHG) value
        rd = rd | (ichg & 0x7F); 
        _setReg(BQ25895_REG04, rd);
    }
    
    function _setChrgTermCurr(iterm) {
        // Ensure value is within range 64mA and 1024mA and calculate
        // value with offset: 64mA and resolution: 64mA         
        iterm = (_limit(iterm, 64, 1024) - 64) / 64;

        // Get current register value
        local rd = _getReg(BQ25895_REG05);
        // Clear Termination Current Limit (ITERM) bits (0-3)
        rd = rd & ~(0x0F); 

        // Update register value with new termination current (ITERM) value;
        rd = rd | (iterm.tointeger() & 0x0F); 
        _setReg(BQ25895_REG05, rd); 
    }

    function _disableWatchdog() {
        // Set WATCHDOG reg bits (4-5) to 00
        local rd = _getReg(BQ25895_REG07);
        _setReg(BQ25895_REG07, rd & 0xCF);
    }

    // Helper to limit value to within specified range
    function _limit(val, min, max) {
        if (val < min) return min;
        if (val > max) return max;
        return val;
    }

    // ADC CONVERSION HELPERS
    // --------------------------------------------------------

    function _convStart() {
        // Only one conversion start is needed
        if (_convStarted) return;

        // Toggle conversion flag so only one conversion is triggered at a time
        _convStarted = true;
        // Make sure only one set of polling timer exists
        _cancelConvTmr();
        _cancelConvTimeout();

        // NOTE: ADC conversion time nominal 8ms, max 1s, imp.wakeup min is ~0.01
        // Set CONV_START bit
        try {
            _setRegBit(BQ25895_REG02, 7, 1);
        } catch(e) {
            _triggerConvDoneFlow(e);
            return;
        }
        
        // Poll register to see when ADC conversion completes
        _convTmr = imp.wakeup(BQ25895_CONV_CHECK_SEC, _checkConvStart.bindenv(this));

        // Don't poll forever, set a timeout 
        _startConvTimeout();
    }

    function _checkConvStart() {
        try {
            // Check BQ25895_REG02 CONV_START bit
            local rd = _getReg(BQ25895_REG02);

            if (rd & 0x80) {
                // ADC conversion is not complete yet
                // Make sure only one polling timer exists
                _cancelConvTmr();
                // Schedule next ADC conversion check
                _convTmr = imp.wakeup(BQ25895_CONV_CHECK_SEC, _checkConvStart.bindenv(this));
            } else {
                // ADC conversion is complete 
                // Trigger callbacks with no error
                _triggerConvDoneFlow(null);
            }
        } catch(e) {
            // Trigger callbacks with error
            _triggerConvDoneFlow(e);
            return;
        }
    }

    function _triggerConvDoneFlow(err) {
        // Cancel polling timer
        _cancelConvTmr();
        // Cancel timeout timer
        _cancelConvTimeout();

        // Trigger callbacks 
        foreach (cb in _convCbs) {
            cb(err);
        }

        // Reset conversion flag and callbacks
        _convStarted = false;
        _convCbs = [];
    }

    function _convCbFactory(reg, mask, offset, resolution, convert, cb) {
        return function(err) {
            if (err) {
                // Pass error to callback
                cb(err, null);
                return;
            }

            try {
                // Get register value
                local rd = _getReg(reg);
                // Calculate value using Register mask, Offset, Resolution
                local result = ((rd & mask) * resolution) + offset;
                // Convert mV to Volts if needed
                if (convert) result /= 1000.0;

                // Pass results to callback
                cb(null, result);
            } catch(e) {
                cb(e, null);
            }  
        }.bindenv(this);
    }

    function _startConvTimeout() {
        _convTimeout = imp.wakeup(BQ25895_CONV_TIMEOUT_SEC, function() {
            // Trigger callbacks with error 
            _triggerConvDoneFlow("[ERROR]: BQ25895 ADC conversion timed out");
        }.bindenv(this));
    }

    function _cancelConvTmr() {
        if (_convTmr != null) {
            imp.cancelwakeup(_convTmr);
            _convTmr = null;
        }
    }

    function _cancelConvTimeout() {
        if (_convTimeout != null) {
            imp.cancelwakeup(_convTimeout);
            _convTimeout = null;
        }
    }

    // REGISTER GETTER/SETTERS
    // --------------------------------------------------------

    function _getReg(reg) {
        local result = _i2c.read(_addr, reg.tochar(), 1);
        if (result == null) throw "[ERROR]: I2C read error " + _i2c.readerror();
        return result[0];
    }

    function _setReg(reg, val) {
        local result = _i2c.write(_addr, format("%c%c", reg, (val & 0xff)));
        if (result) throw "[ERROR]: I2C write error " + result;
        return result;
    }

    function _setRegBit(reg, bit, state) {
        local val = _getReg(reg);
        val = (state == 0) ? val & ~(0x01 << bit) : val | (0x01 << bit);
        return _setReg(reg, val);
    }

}