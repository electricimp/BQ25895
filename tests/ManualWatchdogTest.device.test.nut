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

const BQ25895_DEFAULT_I2C_ADDR = 0xD4;
// From data sheet watchdog timer: default is 40s, max is 160s
const WATCHDOG_TEST_EXP_TIME_SEC = 165;

// NOTE: This test takes ~3m to run.
// This test requires hardware. Test currently configured for an impC001 and  
// impC001 rev5.0 breakout board with battery charger chip on i2c KL. This test 
// should work for both BQ25895 and BQ25895M.
class ManualWatchdogTest extends ImpTestCase {
    
    _i2c     = null;
    _charger = null;
    _hb      = null;
    _wdTimeoutStartTime = null;

    function setUp() {
        // impC001 breakout board rev5.0 
        _i2c = hardware.i2cKL;
        _i2c.configure(CLOCK_SPEED_400_KHZ);
        _charger = BQ25895(_i2c);
        return "Watchdog test setup complete.";
    }

    // Helper to let user know test is still running
    function heartbeat() {
        cancelHearbeat();
        logPercentWdTestDone();
        _hb = imp.wakeup(15, heartbeat.bindenv(this));
    }

    function logPercentWdTestDone() {
        local testRunTime = time() - _wdTimeoutStartTime;
        local percentDone = 100 * testRunTime /  WATCHDOG_TEST_EXP_TIME_SEC;
        info("Watchdog test running. Test " + percentDone + "% done.");
    }

    // Helper to stop heartbeat log
    function cancelHearbeat() {
        if (_hb != null) {
            imp.cancelwakeup(_hb);
            _hb = null;
        }
    }

    function testWatchdog() {
        // Maker sure the charger's has default settings
        _charger.reset();
        // Store default charge voltage (before enable)
        local defaultVoltage = _charger.getChargeVoltage();
        // Enable with non-default settings
        _charger.enable({"voltage" : 4.0});

        // Check settings have changed after enable
        local userSetVoltage = _charger.getChargeVoltage();
        assertTrue(defaultVoltage != userSetVoltage, "User set charge voltage should not match default voltage");
        
        // Wait to ensure watchdog timer has time to expire 
        return Promise(function(resolve, reject) {
            // Create a hearbeat log, so user sees that test is still running
            _wdTimeoutStartTime = time();
            heartbeat();
            // Check settings after watchdog would have reset (default is 40s, max is 160s)
            imp.wakeup(WATCHDOG_TEST_EXP_TIME_SEC, function() {
                cancelHearbeat();
                logPercentWdTestDone();
                local afterTimerVoltage = _charger.getChargeVoltage();
                assertTrue(defaultVoltage != afterTimerVoltage, "User set charge voltage should not match default voltage");
                assertEqual(userSetVoltage, afterTimerVoltage, "User set charge voltage should be the same after 160s");
                return resolve("Watchdog test passed");
            }.bindenv(this))
        }.bindenv(this))
    }

    function tearDown() {
        return "Watchdog tests finished.";
    }

}
