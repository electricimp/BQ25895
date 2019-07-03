// MIT License
//
// Copyright 2015-19 Electric Imp
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

@include __PATH__+ "/StubbedI2C.device.nut"

const BQ25895_DEFAULT_I2C_ADDR = 0xD4;

class StubbedHardwareTests extends ImpTestCase {
    
    _i2c    = null;
    _charger = null;

    function _cleari2cBuffers() {
        // Clear all buffers
        _i2c._clearWriteBuffer();
        _i2c._clearReadResp();
    }

    function setUp() {
        _i2c = StubbedI2C();
        _i2c.configure(CLOCK_SPEED_400_KHZ);
        _charger = BQ25895(_i2c);
        return "Stubbed hardware test setup complete.";
    }    

    function testConstructorDefaultParams() {
        assertEqual(BQ25895_DEFAULT_I2C_ADDR, _charger._addr, "Defult i2c address did not match expected");
        return "Constructor default params test complete.";
    }

    function testConstructorOptionalParams() {
        local customAddr = 0xBA;
        local charger = BQ25895(_i2c, customAddr);
        assertEqual(customAddr, charger._addr, "Non default i2c address did not match expected");
        return "Constructor optional params test complete.";
    }

    function testEnableDefaults() {
        // Note: Limitation of stubbed class, all read values are set before enable
        // so 2 set bit calls back to back are not effected by register write commands
        _cleari2cBuffers();
        // Set readbuffer values
        // REG04 to 0x00
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG04.tochar(), "\x00");    
        // REG05 to 0x10
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG05.tochar(), "\x10");
        // REG06 to 0x02, 
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG06.tochar(), "\x02");
        // REG07 to 0x9D,
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG07.tochar(), "\x9D");
        // REG09 to 0xC4
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG09.tochar(), "\xC4");

        // Test empty settings table
        _charger.enable();

        // Write commands in enable:
            // (REG02 0x3D) Enable HVDCP_EN & MAXC_EN handshakes
            // (REG07 bits 4-5 to 00) Disable watchdog 
            // (REG03 0x3A) Enable charger and min system voltage 
            // (REG06 0x5E) Set charge voltage, 4.208
            // (REG04 0x20) Set charge current, 2048
            // (REG09 bit7 to 0) Set charge current optimizer to default 0
            // (REG05 0x13) Set charge termination current limit to default, 256
        local expected = format("%c%s%c%s%c%s%c%s%c%s%c%s%c%s", 
            BQ25895_REG02, "\x3D", 
            BQ25895_REG07, "\x8D",
            BQ25895_REG03, "\x3A",
            BQ25895_REG06, "\x5E",
            BQ25895_REG04, "\x20",
            BQ25895_REG09, "\x44",
            BQ25895_REG05, "\x13"        
        );
        local actual = _i2c._getWriteBuffer(BQ25895_DEFAULT_I2C_ADDR);
        assertEqual(expected, actual, "Enable with defualt params did not match expected results");
        
        _cleari2cBuffers();
        return "Enable with defualt params test passed";
    }

    function testEnableBQ25895MDefaults() {
        // Note: Limitation of stubbed class, all read values are set before enable
        // so 2 set bit calls back to back are not effected by register write commands
        _cleari2cBuffers();
        // Set readbuffer values
        // REG04 to 0x00
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG04.tochar(), "\x00");    
        // REG05 to 0x10
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG05.tochar(), "\x10");
        // REG06 to 0x02, 
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG06.tochar(), "\x02");
        // REG07 to 0xAD,
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG07.tochar(), "\xAD");
        // REG09 to 0xC4
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG09.tochar(), "\xC4");

        // Test that BQ25895Defaults are set (even if current and voltage are passed in)
        _charger.enable({
            "BQ25895MDefaults" : true,
            "voltage" : 3.0,
            "current" : 1803
        });

        // Write commands in enable:
            // (REG02 0x31) Disable HVDCP_EN & MAXC_EN handshakes
            // (REG07 bits 4-5 to 00) Disable watchdog 
            // (REG03 0x3A) Enable charger and min system voltage 
            // (REG06 0x82) Set charge voltage, 4.352
            // (REG04 0x20) Set charge current, 2048
            // (REG09 bit7 to 0) Set charge current optimizer to default 0
            // (REG05 0x13) Set charge termination current limit to default, 256
        local expected = format("%c%s%c%s%c%s%c%s%c%s%c%s%c%s", 
            BQ25895_REG02, "\x31",            
            BQ25895_REG07, "\x8D",
            BQ25895_REG03, "\x3A",
            BQ25895_REG06, "\x82",
            BQ25895_REG04, "\x20",
            BQ25895_REG09, "\x44",
            BQ25895_REG05, "\x13"        
        );
        local actual = _i2c._getWriteBuffer(BQ25895_DEFAULT_I2C_ADDR);
        assertEqual(expected, actual, "Enable with defualt BQ25895 params did not match expected results");
        
        _cleari2cBuffers();
        return "Enable with defualt BQ25895 params test passed";
    }

    function testEnableCustomVoltAndCurr() {
        // Note: Limitation of stubbed class, all read values are set before enable
        // so 2 set bit calls back to back are not effected by register write commands
        _cleari2cBuffers();
        // Set readbuffer values
        // REG04 to 0x00
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG04.tochar(), "\x80");    
        // REG05 to 0x10
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG05.tochar(), "\x10");
        // REG06 to 0x02, 
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG06.tochar(), "\x02");
        // REG07 to 0xAD,
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG07.tochar(), "\x9D");
        // REG09 to 0xC4
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG09.tochar(), "\xC4");

        // Test that BQ25895Defaults are not set and current and voltage settings are configured
        _charger.enable({
            "BQ25895MDefaults" : false,
            "voltage" : 4.2,
            "current" : 2000
        });

        // Write commands in enable:
            // (REG02 0x3D) Enable HVDCP_EN & MAXC_EN handshakes
            // (REG07 bits 4-5 to 00) Disable watchdog 
            // (REG03 0x3A) Enable charger and min system voltage 
            // (REG06 0x5A) Set charge voltage, 4.2 
            // (REG04 0x9F) Set charge current, 2000
            // (REG09 bit7 to 0) Set charge current optimizer to default 0
            // (REG05 0x13) Set charge termination current limit to default, 256
        local expected = format("%c%s%c%s%c%s%c%s%c%s%c%s%c%s",
            BQ25895_REG02, "\x3D",          
            BQ25895_REG07, "\x8D",
            BQ25895_REG03, "\x3A",
            BQ25895_REG06, "\x5A", 
            BQ25895_REG04, "\x9F",
            BQ25895_REG09, "\x44",
            BQ25895_REG05, "\x13"        
        );
        local actual = _i2c._getWriteBuffer(BQ25895_DEFAULT_I2C_ADDR);
        assertEqual(expected, actual, "Enable with custom voltage and current params did not match expected results");
        
        _cleari2cBuffers();
        return "Enable with custom voltage and current params test passed";
    }

    function testEnableVCOutOfRange() {
        // Note: Limitation of stubbed class, all read values are set before enable
        // so 2 set bit calls back to back are not effected by register write commands
        _cleari2cBuffers();
        // Set readbuffer values
        // REG04 to 0x00
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG04.tochar(), "\x00");    
        // REG05 to 0x10
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG05.tochar(), "\x10");
        // REG06 to 0x02, 
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG06.tochar(), "\x02");
        // REG07 to 0xAD,
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG07.tochar(), "\x9D");
        // REG09 to 0xC4
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG09.tochar(), "\xC4");

        // Test that current and voltage are limited
        _charger.enable({
            "voltage" : 5.0,
            "current" : 6000
        });

        // Write commands in enable:
            // (REG02 0x3D) Enable HVDCP_EN & MAXC_EN handshakes
            // (REG07 bits 4-5 to 00) Disable watchdog 
            // (REG03 0x3A) Enable charger and min system voltage 
            // (REG06 0xC2) Set charge voltage, 5.0 
            // (REG04 0xCF) Set charge current, 6000
            // (REG09 bit7 to 0) Set charge current optimizer to default 0
            // (REG05 0x13) Set charge termination current limit to default, 256
        local expected = format("%c%s%c%s%c%s%c%s%c%s%c%s%c%s",    
            BQ25895_REG02, "\x3D",       
            BQ25895_REG07, "\x8D",
            BQ25895_REG03, "\x3A",
            BQ25895_REG06, "\xC2", 
            BQ25895_REG04, "\x4F", 
            BQ25895_REG09, "\x44",
            BQ25895_REG05, "\x13"        
        );
        local actual = _i2c._getWriteBuffer(BQ25895_DEFAULT_I2C_ADDR);
        assertEqual(expected, actual, "Enable with out of range high voltage and current params did not match expected results");
        
        _cleari2cBuffers();
        // Set readbuffer values
        // REG04 to 0x00
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG04.tochar(), "\x80");    
        // REG05 to 0x10
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG05.tochar(), "\x10");
        // REG06 to 0x02, 
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG06.tochar(), "\x02");
        // REG07 to 0xAD,
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG07.tochar(), "\x9D");
        // REG09 to 0xC4
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG09.tochar(), "\xC4");

        // Test that current and voltage are limited
        _charger.enable({
            "voltage" : 3.0,
            "current" : -1
        });

        // Write commands in enable:
            // (REG02 0x3D) Enable HVDCP_EN & MAXC_EN handshakes
            // (REG07 bits 4-5 to 00) Disable watchdog 
            // (REG03 0x3A) Enable charger and min system voltage 
            // (REG06 0x02) Set charge voltage, 3.0 
            // (REG04 0x00) Set charge current, -1
            // (REG09 bit7 to 0) Set charge current optimizer to default 0
            // (REG05 0x13) Set charge termination current limit to default, 256
        local expected = format("%c%s%c%s%c%s%c%s%c%s%c%s%c%s", 
            BQ25895_REG02, "\x3D",            
            BQ25895_REG07, "\x8D",
            BQ25895_REG03, "\x3A",
            BQ25895_REG06, "\x02", 
            BQ25895_REG04, "\x80",
            BQ25895_REG09, "\x44",
            BQ25895_REG05, "\x13"        
        );
        local actual = _i2c._getWriteBuffer(BQ25895_DEFAULT_I2C_ADDR);
        assertEqual(expected, actual, "Enable with out of range low voltage and current params did not match expected results");
        
        _cleari2cBuffers();
        return "Enable with out of range voltage and current params test passed";
    }

    function testEnableSetChargeCurrentOptimizer() {
        // Note: Limitation of stubbed class, all read values are set before enable
        // so 2 set bit calls back to back are not effected by register write commands
        _cleari2cBuffers();
        // Set readbuffer values
        // REG04 to 0x00
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG04.tochar(), "\x00");    
        // REG05 to 0x10
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG05.tochar(), "\x10");
        // REG06 to 0x02, 
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG06.tochar(), "\x02");
        // REG07 to 0x9D,
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG07.tochar(), "\x9D");
        // REG09 to 0x44
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG09.tochar(), "\x44");

        // Test setChargeCurrentOptimizer
        _charger.enable({
            "forceICO" : true
        });

        // Write commands in enable:
            // (REG02 0x3D) Enable HVDCP_EN & MAXC_EN handshakes
            // (REG07 bits 4-5 to 00) Disable watchdog 
            // (REG03 0x3A) Enable charger and min system voltage 
            // (REG06 0x5E) Set charge voltage, 4.208
            // (REG04 0x20) Set charge current, 2048
            // (REG09 bit7 to 1) Set charge current optimizer to 1
            // (REG05 0x13) Set charge termination current limit to default, 256
        local expected = format("%c%s%c%s%c%s%c%s%c%s%c%s%c%s",
            BQ25895_REG02, "\x3D",  
            BQ25895_REG07, "\x8D",
            BQ25895_REG03, "\x3A",
            BQ25895_REG06, "\x5E",
            BQ25895_REG04, "\x20",
            BQ25895_REG09, "\xC4",
            BQ25895_REG05, "\x13"        
        );
        local actual = _i2c._getWriteBuffer(BQ25895_DEFAULT_I2C_ADDR);
        assertEqual(expected, actual, "Enable with charge current optimizer enabled did not match expected results");
        
        _cleari2cBuffers();
        return "Enable with charge current optimizer enabled test passed";
    }

    function testEnableSetChargeTerminationCurrentLimit() {
        // Note: Limitation of stubbed class, all read values are set before enable
        // so 2 set bit calls back to back are not effected by register write commands
        _cleari2cBuffers();
        // Set readbuffer values
        // REG04 to 0x00
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG04.tochar(), "\x00");    
        // REG05 to 0x10
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG05.tochar(), "\x10");
        // REG06 to 0x02, 
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG06.tochar(), "\x02");
        // REG07 to 0x9D,
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG07.tochar(), "\x9D");
        // REG09 to 0xC4
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG09.tochar(), "\xC4");

        // Test setChargeCurrentOptimizer in range
        _charger.enable({
            "forceICO" : false, 
            "chrgTermLimit" : 500
        });

        // Write commands in enable:
            // (REG02 0x3D) Enable HVDCP_EN & MAXC_EN handshakes
            // (REG07 bits 4-5 to 00) Disable watchdog 
            // (REG03 0x3A) Enable charger and min system voltage 
            // (REG06 0x5E) Set charge voltage, 4.208
            // (REG04 0x20) Set charge current, 2048
            // (REG09 bit7 to 0) Set charge current optimizer to 0
            // (REG05 0x13) Set charge termination current limit to default, 256
        local expected = format("%c%s%c%s%c%s%c%s%c%s%c%s%c%s",
            BQ25895_REG02, "\x3D",   
            BQ25895_REG07, "\x8D",
            BQ25895_REG03, "\x3A",
            BQ25895_REG06, "\x5E",
            BQ25895_REG04, "\x20",
            BQ25895_REG09, "\x44",
            BQ25895_REG05, "\x16"        
        );
        local actual = _i2c._getWriteBuffer(BQ25895_DEFAULT_I2C_ADDR);
        assertEqual(expected, actual, "Enable setting charge termination current limit in range did not match expected results");
        
        // Test setChargeCurrentOptimizer too low
        _i2c._clearWriteBuffer();
        _charger.enable({
            "chrgTermLimit" : 10
        });

        // Write commands in enable:
            // (REG02 0x3D) Enable HVDCP_EN & MAXC_EN handshakes
            // (REG07 bits 4-5 to 00) Disable watchdog 
            // (REG03 0x3A) Enable charger and min system voltage 
            // (REG06 0x5E) Set charge voltage, 4.208
            // (REG04 0x20) Set charge current, 2048
            // (REG09 bit7 to 0) Set charge current optimizer to 0
            // (REG05 0x10) Set charge termination current limit to 64
        local expected = format("%c%s%c%s%c%s%c%s%c%s%c%s%c", 
            BQ25895_REG02, "\x3D",
            BQ25895_REG07, "\x8D",
            BQ25895_REG03, "\x3A",
            BQ25895_REG06, "\x5E",
            BQ25895_REG04, "\x20",
            BQ25895_REG09, "\x44",
            BQ25895_REG05) + "\x10"; // String format with non-printable chars, doesn't always work, use string concat to add last val
        actual = _i2c._getWriteBuffer(BQ25895_DEFAULT_I2C_ADDR);
        assertEqual(expected, actual, "Enable setting charge termination current limit below min did not match expected results");
    
        // Test setChargeCurrentOptimizer too high
        _i2c._clearWriteBuffer();
        _charger.enable({
            "chrgTermLimit" : 2000
        });

        // Write commands in enable:
            // (REG02 0x3D) Enable HVDCP_EN & MAXC_EN handshakes
            // (REG07 bits 4-5 to 00) Disable watchdog 
            // (REG03 0x3A) Enable charger and min system voltage 
            // (REG06 0x5E) Set charge voltage, 4.208
            // (REG04 0x20) Set charge current, 2048
            // (REG09 bit7 to 0) Set charge current optimizer to 0
            // (REG05 0x1F) Set charge termination current limit to 1024
        local expected = format("%c%s%c%s%c%s%c%s%c%s%c%s%c%s", 
            BQ25895_REG02, "\x3D",
            BQ25895_REG07, "\x8D",
            BQ25895_REG03, "\x3A",
            BQ25895_REG06, "\x5E",
            BQ25895_REG04, "\x20",
            BQ25895_REG09, "\x44",
            BQ25895_REG05, "\x1F"        
        );
        local actual = _i2c._getWriteBuffer(BQ25895_DEFAULT_I2C_ADDR);
        assertEqual(expected, actual, "Enable setting charge termination current limit above max did not match expected results");
        
        _cleari2cBuffers();
        return "Enable setting charge termination current limit test passed";
    }

    function testDisable() {
        // Note: Limitation of stubbed class, all read values are set before enable
        // so 2 set bit calls back to back are not effected by register write commands
        _cleari2cBuffers();
        // Set readbuffer values
        // REG03 to 0x3A
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG03.tochar(), "\x3A");    
        // REG07 to 0x9D,
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG07.tochar(), "\x9D");

        // Test setChargeCurrentOptimizer in range
        _charger.disable();

        // Test REG03 bit toggles as expected
        // Write commands in enable:
            // (REG07 bits 4-5 to 00) Disable watchdog 
            // (REG03 0x2A) Disable charging (bit 4 set to 0)  
        local expected = format("%c%s%c%s", 
            BQ25895_REG07, "\x8D",
            BQ25895_REG03, "\x2A"
        );
        local actual = _i2c._getWriteBuffer(BQ25895_DEFAULT_I2C_ADDR);
        assertEqual(expected, actual, "Disable did not match expected results");
        
        _cleari2cBuffers();
        return "Disable test passed";
    }

    function testGetChargeVoltage() {
        // Test that REG06 set to known val, getChargeVoltage returns expected value
        _cleari2cBuffers();
        // Set readbuffer values
        // REG06 to 0x82
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG06.tochar(), "\x82");

        local expected = 4.352;
        local actual = _charger.getChrgTermV();
        assertEqual(expected, actual, "Get charge voltage did not match expected results");
        
        _cleari2cBuffers();
        return "Get charge voltage test passed";
    }

    function testAsyncGetI2CError() {
        // Test that callback contains i2c error 
        _cleari2cBuffers();
        // Set readbuffer values
        // REG02 to 0x00 (need bit 7 in REG02 to be 0 for converstion flow to pass)
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG02.tochar(), "\x00");
        // // REG0E to 0x00
        // _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG0E.tochar(), "\x07");

        return Promise(function(resolve, reject) {
            _charger.getBattV(function(err, actual) {

                assertTrue(err != null, "Async getter did not return expected error");
                local idx = err.find("[ERROR]: I2C read error");
                assertTrue(idx != null, "Expected error not found");
                
                // Make sure all conversion varaibles have cleared
                imp.wakeup(0, function() {
                    assertEqual(0, _charger._convCbs.len(), "Conversion callbacks not cleared");
                    assertTrue(!_charger._convStarted, "Conversion flag not cleared");
                    assertEqual(null, _charger._convTmr, "Conversion timer not cleared");
                    assertEqual(null, _charger._convTimeout, "Conversion timeout timer not cleared");
                    
                    _cleari2cBuffers();
                    return resolve("Async getter with i2c error test passed");
                }.bindenv(this))
            }.bindenv(this));
        }.bindenv(this));
    }

    function testGetBatteryVoltage() {
        // Test that REG0E  set to known val, getBatteryVoltage returns expected value
        _cleari2cBuffers();
        // Set readbuffer values
        // REG02 to 0x00 (need bit 7 in REG02 to be 0 for converstion flow to pass)
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG02.tochar(), "\x00");
        // REG0E to 0x00
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG0E.tochar(), "\x07");

        return Promise(function(resolve, reject) {
            _charger.getBattV(function(err, actual) {
                local expected = 2.304 + 0.140;
                assertEqual(expected, actual, "Get battery voltage did not match expected results");
            
                _cleari2cBuffers();
                return resolve("Get battery voltage test passed");
            }.bindenv(this));
        }.bindenv(this));
    }

    function testGetBatteryVoltageTimeout() {
        // Test that REG0E  set to known val, getBatteryVoltage returns expected value
        _cleari2cBuffers();
        // Set readbuffer values
        // REG02 to 0x80 (need bit 7 in REG02 to be 1 for converstion flow to fail)
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG02.tochar(), "\x80");
        // REG0E to 0x00
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG0E.tochar(), "\x07");

        return Promise(function(resolve, reject) {
            _charger.getBattV(function(err, actual) {
                local expectedErr = "[ERROR]: BQ25895 ADC conversion timed out";
                local expected = null;
                assertEqual(expectedErr, err, "Get battery voltage timeout did not match expected error");
                assertEqual(expected, actual, "Get battery voltage timeout did not match expected results");
                
                _cleari2cBuffers();
                return resolve("Get battery voltage timeout test passed");
            }.bindenv(this));
        }.bindenv(this));
    }

    function testGetBatteryVoltageDelay() {
        // Test that REG0E  set to known val, getBatteryVoltage returns expected value
        _cleari2cBuffers();
        // Set readbuffer values
        // REG02 to 0x80 (need bit 7 in REG02 to be 1 for converstion flow to fail)
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG02.tochar(), "\x80");
        // REG0E to 0x00
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG0E.tochar(), "\x07");

        return Promise(function(resolve, reject) {
            imp.wakeup(0.2, function() {
                // Update REG02 to 0x00, to see polling catch change
                _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG02.tochar(), "\x00");
            }.bindenv(this))
            _charger.getBattV(function(err, actual) {
                local expectedErr = null;
                local expected = 2.304 + 0.140;
                assertEqual(expectedErr, err, "Get battery voltage delay did not match expected error");
                assertEqual(expected, actual, "Get battery voltage delay did not match expected results");
                
                _cleari2cBuffers();
                return resolve("Get battery voltage delay test passed");
            }.bindenv(this));
        }.bindenv(this));
    }

    function testGetVBUSVoltage() {
        // Test that REG11 set to known val, getBatteryVoltage returns expected value
        _cleari2cBuffers();
        // Set readbuffer values
        // REG02 to 0x00 (need bit 7 in REG02 to be 0 for converstion flow to pass)
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG02.tochar(), "\x00");
        // REG11 to 0x7F
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG11.tochar(), "\x7F");

        return Promise(function(resolve, reject) {
            _charger.getVBUSV(function(err, actual) {
                local expected = 15.3;
                assertEqual(expected, actual, "Get VBUS voltage did not match expected results");
            
                _cleari2cBuffers();
                return resolve("Get VBUS voltage test passed");
            }.bindenv(this));
        }.bindenv(this));
    }

    function testGetSystemVoltage() {
        // Test that REG0F set to known val, getSystemVoltage returns expected value
        _cleari2cBuffers();
        // Set readbuffer values
        // REG02 to 0x00 (need bit 7 in REG02 to be 0 for converstion flow to pass)
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG02.tochar(), "\x00");
        // REG0F to 0x07
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG0F.tochar(), "\x07");

        return Promise(function(resolve, reject) {
            _charger.getSysV(function(err, actual) {
                local expected = 2.304 + 0.140;
                assertEqual(expected, actual, "Get system voltage did not match expected results");
            
                _cleari2cBuffers();
                return resolve("Get system voltage test passed");
            }.bindenv(this));
        }.bindenv(this));
    }

    function testGetInputStatus() {
        // Test that REG0B & REG00 set to known vals, getInputStatus returns expected value
        _cleari2cBuffers();
        // Set readbuffer values
        // REG00 to 0xFF
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG00.tochar(), "\xFF");
        // REG0B to 0x5F
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG0B.tochar(), "\x5F");

        local expectedVBus   = BQ25895_VBUS_STATUS.USB_CDP;
        local expectedInCurr = 3250;
        local actual = _charger.getInputStatus();
        assertTrue(("vbus" in actual && "currLimit" in actual) "Get input status did return expected table slots");
        assertEqual(expectedVBus, actual.vbus, "Get input status VBUS status did not match expected results");
        assertEqual(expectedInCurr, actual.currLimit, "Get input status input current limit did not match expected results");

        _cleari2cBuffers();
        return "Get input status test passed";
    }

    function testGetChargingCurrent() {
        // Test that REG12 set to known val, getChargingCurrent returns expected value
        _cleari2cBuffers();
        // Set readbuffer values
        // REG02 to 0x00 (need bit 7 in REG02 to be 0 for converstion flow to pass)
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG02.tochar(), "\x00");
        // REG12 to 0x7F
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG12.tochar(), "\x7F");

        return Promise(function(resolve, reject) {
            _charger.getChrgCurr(function(err, actual) {
                local expected = 6350;
                assertEqual(expected, actual, "Get charging current did not match expected results");
            
                _cleari2cBuffers();
                return resolve("Get charging current test passed");
            }.bindenv(this));
        }.bindenv(this));
    }

    function testGetChargingStatus() {
        // Test that REG0B set to known val, getChargingStatus returns expected value
        _cleari2cBuffers();
        // Set readbuffer values
        // REG0B to 0x7F
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG0B.tochar(), "\xF7");

        local expected = BQ25895_CHARGING_STATUS.FAST_CHARGING;
        local actual = _charger.getChrgStatus();
        assertEqual(expected, actual, "Get charging status did not match expected results");

        _cleari2cBuffers();
        return "Get charging status test passed";
    }

    function testGetChargerFaults() {
        // Test that REG0C set to known val, getChargerFaults returns expected value
        _cleari2cBuffers();
        // Set readbuffer values
        // REG0C to 0xFE
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG0C.tochar(), "\xFE");

        local expectedWatchdog   = true;
        local expectedBoostFault = true;
        local expectedChrgFault  = BQ25895_CHARGING_FAULT.CHARGE_SAFETY_TIMER_EXPIRATION;
        local expectedBattFault  = true;
        local expectedNtcFault   = BQ25895_NTC_FAULT.TS_HOT;
        local actual = _charger.getChrgFaults();

        assertTrue("watchdog" in actual, "Get charging faults table missing watchdog slot");
        assertTrue("boost" in actual, "Get charging faults table missing boost slot");
        assertTrue("chrg" in actual, "Get charging faults table missing charge slot");
        assertTrue("batt" in actual, "Get charging faults table missing battery slot");
        assertTrue("ntc" in actual, "Get charging faults table missing NTC slot");
        assertEqual(expectedWatchdog, actual.watchdog, "Get charging faults watchdog did not match expected results");
        assertEqual(expectedBoostFault, actual.boost, "Get charging faults boost did not match expected results");
        assertEqual(expectedChrgFault, actual.chrg, "Get charging faults charge did not match expected results");
        assertEqual(expectedBattFault, actual.batt, "Get charging faults battery did not match expected results");
        assertEqual(expectedNtcFault, actual.ntc, "Get charging faults NTC did not match expected results");

        _cleari2cBuffers();
        return "Get charging faults test passed";
    }

    function testReset() {
        _cleari2cBuffers();
        // Set read buffer for toggling register 0x14 bit
        _i2c._setReadResp(BQ25895_DEFAULT_I2C_ADDR, BQ25895_REG14.tochar(), "\x01");

        // Call reset
        _charger.reset();

        // Write commands in reset:
            // (REG014 bit7 to 1) Set reset bit
            // (REG014 bit7 to 0) Clear reset bit
        local expected = format("%c%s%c%s", 
            BQ25895_REG14, "\x81",
            BQ25895_REG14, "\x01"
        );

        local actual = _i2c._getWriteBuffer(BQ25895_DEFAULT_I2C_ADDR);
        assertEqual(expected, actual, "Reset did not match expected results");
        
        _cleari2cBuffers();
        return "Reset test passed";
    }

    function tearDown() {
        return "Stubbed hardware tests finished.";
    }

}