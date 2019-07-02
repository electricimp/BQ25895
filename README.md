# BQ25895 3.0.0 #

The library provides a driver for the [BQ25895](https://www.ti.com/lit/ds/symlink/bq25895.pdf) and the [BQ25895M](http://www.ti.com/lit/ds/symlink/bq25895m.pdf) switch-mode battery charge and system power path management devices for single-cell Li-Ion and Li-polymer batteries. Theses ICs support high input voltage fast charging and communicates over an I&sup2;C interface. The BQ25895 and the BQ25895M have different default settings &mdash; please see the [*enable()*](#enablesettings) method for details of the default charge settings.

**Note 1** When using an impC001 breakout board without a battery connected it is recommended that you always enable the battery charger with BQ25895 default settings. If a battery is connected, please follow [the instructions in the Examples](./Examples/README.md) directory to determine the correct settings for your battery.

**Note 2** This library supersedes the BQ25895M library, which is now deprecated and will not be maintained. We strongly recommend that you update to the the new library, but please be aware that this incorporates a **breaking change** which you will need to accommodate. Please see the [*enable()*](#enablesettings) method description for details.

**To include this library in your project, add** `#require "BQ25895.device.lib.nut:3.0.0"` **at the top of your device code.**

## Class Usage ##

### Callbacks ###

An ADC conversion can take up to one full second to return a value, therefore all library methods that require an ADC conversion are asynchronous. These methods take a callback function as a mandatory argument. These callback functions have two parameters of their own: *error* and *result*. The *error* parameter will receive `null` as an argument if no error was encountered, or a string containing an error message. The *result* parameter’s argument will be will the result of the value requested and be either an integer or float, depending on the method in question.

### Constructor: BQ25895(*i2cBus [,i2cAddress]*) ###

The constructor *does not configure the battery charger*. It is recommended that either the [*enable()*](#enablesettings) method is called and passed settings for your battery, or the [*disable()*](#disable) method is called immediately after the constructor and on cold boots.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *i2cBus* | imp i2c bus object | Yes | The imp I&sup2;C bus that the BQ25895/BQ25895M is connected to. The I&sup2;C bus **must** be pre-configured &mdash; the library will not configure the bus |
| *i2cAddress* | Integer | No | The BQ25895's I&sup2;C address. Default: 0xD4 |

#### Example ####

```squirrel
#require "BQ25895.device.lib.nut:3.0.0"

// Alias and configure an impC001 I2C bus
local i2c = hardware.i2cKL;
i2c.configure(CLOCK_SPEED_400_KHZ);

// Instantiate a BQ25895 object
batteryCharger <- BQ25895(i2c);
```

## Class Methods ##

### enable(*[settings]*) ###

This method configures and enables the battery charger with settings to perform a charging cycle when a battery is connected and an input source is available. It is recommended that this method is called immediately after the constructor and on cold boots with the settings for your battery.

For the BQ25895, the defaults are 4.208V and 2048mA. For the BQ25895M, the defaults are 4.352V and 2048mA, which you apply by adding the key *BQ25895MDefaults* and the value `true` in a table of settings passed into the method. Please ensure you confirm that these defaults are suitable for your battery &mdash; see [**Setting Up The BQ25895 Library For Your Battery**](./Examples/README.md) for guidance.

**IMPORTANT** The default settings applied by the library have been changed from those set by this library’s predecessor, the BQ25895M library. You must consider this a breaking change when upgrading to the new library, and ensure your code calls *enable()* with the correct settings &mdash; see the examples below.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *settings* | Table | No | A table of additional settings &mdash; see [**Settings Options**](#settings-options), below |

##### Settings Options #####

| Key | Type | Description |
| --- | --- | --- |
| *BQ25895MDefaults* | Boolean | Whether to enable the charger with defaults for the BQ25895M part. If `true` the *chargeVoltage* is set to `4.352V` and *currentLimit* to `2048mA`. Default: `false` |
| *voltage* | Float | The desired charge voltage in Volts. Range: 3.84-4.608V. Default: 4.208V.<br />**Note** If *BQ25895MDefaults* flag is set to `true`, this value will be ignored |
| *current* | Integer | The desired fast-charge current limit in mA. Range: 0-5056mA. Default: 2048mA.<br />**Note** If *BQ25895MDefaults* flag is set to `true`, this value will be ignored |
| *forceICO* | Boolean | Whether to force start the input current optimizer. Default: `false` |
| *chrgTermLimit* | Integer | The current at which the charge cycle will be terminated when the battery voltage is above the recharge threshold. Range: 64-1024mA. Default: 256mA |

#### Return Value ####

Nothing.

#### Example 1: Using the BQ25895 with Defaults ####

```squirrel
// Configure battery charger with default setting for BQ25895,
// ie. a charge voltage of 4.208V and current limit of 2048mA.
batteryCharger.enable();
```

#### Example 2: Using the BQ25895 with Other Settings ####

```squirrel
// Configure battery charger for BQ25895 to charge at 4.0V
// to a maximum of 2000mA
local settings = { "voltage" : 4.0,
                   "current" : 2000 };
batteryCharger.enable(settings);
```

#### Example 3: Using the BQ25895M with Defaults ####

```squirrel
// Configure battery charger with default setting for BQ25895M,
// ie. charge voltage of 4.352V and current limit of 2048mA.
batteryCharger.enable({"BQ25895MDefaults": true});
```

### disable() ###

This method disables the device's charging capabilities. The battery will not charge until [*enable()*](#enablesettings) is called.

#### Return Value ####

Nothing.

#### Example ####

```squirrel
// Disable charging
batteryCharger.disable();
```

### getChrgTermV() ###

This method gets the charge termination voltage for the battery.

#### Return Value ####

Float &mdash; The charge voltage limit in Volts.

#### Example ####

```squirrel
local voltage = batteryCharger.getChrgTermV();
server.log("Charge Termination Voltage: " + voltage + "V");
```

### getBattV(*callback*) ###

This method retrieves the battery's voltage based on an internal ADC conversion. If the request is successful, the result will be a float: the battery voltage in Volts, returned via the function passed into the method's *callback* parameter.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *callback* | Function | Yes | See [Class Usage: Callbacks](#callbacks) for details |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
batteryCharger.getBattV(function(error, voltage) {
    if (error != null) {
        server.error(error);
        return;
    }

    server.log("Battery Voltage (ADC): " + voltage + "V");
});
```

### getVBUSV(*callback*) ###

This method gets the V<sub>BUS</sub> voltage based on ADC conversion. This is the input voltage to the BQ25895. If the request is successful, the result will be a float: the V<sub>BUS</sub> voltage in Volts, returned via the function passed into the method's *callback* parameter.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *callback* | Function | Yes | See [Class Usage: Callbacks](#callbacks) for details |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
batteryCharger.getVBUSV(function(error, voltage) {
    if (error != null) {
        server.log(error);
        return;
    }

    server.log("Voltage (VBUS): " + voltage + "V");
});
```

### getSysV(*callback*) ###

This method gets the system voltage based on the ADC conversion. This the output voltage which can be used to drive other chips in your application. In most impC001-based applications, the system voltage is the impC001 V<sub>MOD</sub> supply. If the request is successful, the result will be a float: the system voltage in Volts, returned via the function passed into the method's *callback* parameter.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *callback* | Function | Yes | See [Class Usage: Callbacks](#callbacks) for details |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
batteryCharger.getSysV(function(error, voltage) {
    if (error != null) {
        server.error(error);
        return;
    }

    server.log("Voltage (system): " + voltage + "V");
});
```

### getChrgCurr(*callback*) ###

This method gets the measured current going to the battery based on the ADC conversion. If the request is successful, the result will be an integer: the charging current in milliAmperes, returned via the function passed into the method's *callback* parameter.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *callback* | Function | Yes | See [Class Usage: Callbacks](#callbacks) for details |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
batteryCharger.getChrgCurr(function(error, current) {
    if (error != null) {
        server.error(error);
        return;
    }

    server.log("Current (charging): " + current + "mA");
});
```

### getInputStatus() ###

This method reports the type of power source connected to the charger input as well as the resulting input current limit.

#### Return Value ####

Table &mdash; An input status report with the following keys:

| Key| Type | Description |
| --- | --- | --- |
| *vbusStatus* | Integer| Possible input states &mdash; see [**V<sub>BUS</sub> Status**](#vsubbussub-status), below, for details |
| *inputCurrentLimit* | Integer| 100-3250mA |

#### V<sub>BUS</sub> Status ####

| V<sub>BUS</sub> Status Constant | Value |
| --- | --- |
| *BQ25895_VBUS_STATUS.NO_INPUT* | 0x00 |
| *BQ25895_VBUS_STATUS.USB_HOST_SDP* | 0x20 |
| *BQ25895_VBUS_STATUS.USB_CDP* | 0x40 |
| *BQ25895_VBUS_STATUS.USB_DCP* | 0x60 |
| *BQ25895_VBUS_STATUS.ADJUSTABLE_HV_DCP* | 0x80 |
| *BQ25895_VBUS_STATUS.UNKNOWN_ADAPTER* | 0xA0 |
| *BQ25895_VBUS_STATUS.NON_STANDARD_ADAPTER* | 0xC0 |
| *BQ25895_VBUS_STATUS.OTG* | 0xE0 |

#### Example ####

```squirrel
local inputStatus = batteryCharger.getInputStatus();
local msg = "";

switch(inputStatus.vbusStatus) {
    case BQ25895_VBUS_STATUS.NO_INPUT:
        msg = "No Input";
        break;
    case BQ25895_VBUS_STATUS.USB_HOST_SDP:
        msg = "USB Host SDP";
        break;
    case BQ25895_VBUS_STATUS.USB_CDP:
        msg = "USB CDP";
        break;
    case BQ25895_VBUS_STATUS.USB_DCP:
        msg = "USB DCP";
        break;
    case BQ25895_VBUS_STATUS.ADJUSTABLE_HV_DCP:
        msg = "Adjustable High Voltage DCP";
        break;
    case BQ25895_VBUS_STATUS.UNKNOWN_ADAPTER:
        msg = "Unknown Adapter";
        break;
    case BQ25895_VBUS_STATUS.NON_STANDARD_ADAPTER:
        msg = "Non-standard Adapter";
        break;
    case BQ25895_VBUS_STATUS.OTG:
        msg = "OTG";
        break;
}

server.log("VBUS status: " + msg);
server.log("Input Current Limit: " + inputStatus.inputCurrentLimit);
```

### getChrgStatus() ###

This method reports the battery charging status.

#### Return Value ####

Integer &mdash; A charging status constant:

| Charging Status Constant| Value |
| --- | --- |
| *BQ25895_CHARGING_STATUS.NOT_CHARGING* | 0x00 |
| *BQ25895_CHARGING_STATUS.PRE_CHARGE* | 0x08|
| *BQ25895_CHARGING_STATUS.FAST_CHARGE* | 0x10|
| *BQ25895_CHARGING_STATUS.CHARGE_TERMINATION_DONE* | 0x18 |

#### Example ####

```squirrel
local status = batteryCharger.getChrgStatus();
switch(status) {
    case BQ25895_CHARGING_STATUS.NOT_CHARGING:
        server.log("Battery is not charging");
        // Do something
        break;
    case BQ25895_CHARGING_STATUS.PRE_CHARGE:
        server.log("Battery pre charging");
        // Do something
        break;
    case BQ25895_CHARGING_STATUS.FAST_CHARGING:
        server.log("Battery is fast charging");
        // Do something
        break;
    case BQ25895_CHARGING_STATUS.CHARGE_TERMINATION_DONE:
        server.log("Battery charging complete");
        // Do something
        break;
}
```

### getChrgFaults() ###

This method reports possible charger faults.

#### Return Value ####

Table &mdash; A charger fault report with the following keys:

| Key/Fault | Type | Description |
| --- | --- | --- |
| *watchdogFault* | Bool | `true` if watchdog timer has expired, otherwise `false` |
| *boostFault* | Bool | `true` if V<sub>MBUS</sub> overloaded in OTG, V<sub>BUS</sub> OVP, or battery is too low, otherwise `false` |
| *chrgFault* | Integer | A charging fault. See [**Charging Faults**](#charging-faults), below, for possible values |
| *battFault* | Bool| `true` if V<sub>BAT</sub> > V<sub>BATOVP</sub>, otherwise `false` |
| *ntcFault* | Integer | An NTC fault. See [**NTC Faults**](#ntc-faults), below, for possible values |

#### Charging Faults ####

| Charging Fault Constant | Value |
| --- | --- |
| *BQ25895_CHARGING_FAULT.NORMAL* | 0x00 |
| *BQ25895_CHARGING_FAULT.INPUT_FAULT* | 0x10 |
| *BQ25895_CHARGING_FAULT.THERMAL_SHUTDOWN* | 0x20 |
| *BQ25895_CHARGING_FAULT.CHARGE_SAFETY_TIMER_EXPIRATION* | 0x30 |

#### NTC Faults ####

| NTC Fault Constant | Value |
| --- | --- |
| *BQ25895_NTC_FAULT.NORMAL* | 0x00 |
| *BQ25895_NTC_FAULT.TS_COLD* | 0x01 |
| *BQ25895_NTC_FAULT.TS_HOT* | 0x02 |

#### Example ####

```squirrel
local faults = batteryCharger.getChrgFaults();

server.log("Fault Report");
server.log("--------------------------------------");
if (faults.watchdogFault) server.log("Watchdog Timer Fault reported");
if (faults.boostFault) server.log("Boost Fault reported");
if (faults.battFault) server.log("VBAT too high");

switch(faults.chrgFault) {
    case BQ25895_CHARGING_FAULT.NORMAL:
        server.log("Charging OK");
        break;
    case BQ25895_CHARGING_FAULT.INPUT_FAULT:
        server.log("Charging NOT OK - Input Fault reported");
        break;
    case BQ25895_CHARGING_FAULT.THERMAL_SHUTDOWN:
        server.log("Charging NOT OK - Thermal Shutdown reported");
        break;
    case BQ25895_CHARGING_FAULT.CHARGE_SAFETY_TIMER_EXPIRATION:
        server.log("Charging NOT OK - Safety Timer expired");
        break;
}

switch(faults.ntcFault) {
    case BQ25895_NTC_FAULT.NORMAL:
        server.log("NTC OK");
        break;
    case BQ25895_NTC_FAULT.TS_COLD:
        server.log("NTC NOT OK - Too Cold");
        break;
    case BQ25895_NTC_FAULT.TS_HOT:
        server.log("NTC NOT OK - Too Hot");
        break;
}

server.log("--------------------------------------");
```

### reset() ###

This method provides a software reset which clears all of the BQ25895's register settings.

**Note** This will reset the charge voltage and current to the register defaults. For the BQ25895, the defaults are 4.208V and 2048mA. For the BQ25895M, the defaults are 4.352V and 2048mA. Please ensure that you confirm these are suitable for your battery &mdash; see [**Setting Up The BQ25895 Library For Your Battery**](./Examples/README.md) for guidance.

If the defaults are not appropriate for your battery, make sure you call [*enable()*](#enablesettings) with the correct settings **immediately** after calling *reset()*.

#### Return Value ####

Nothing.

#### Example ####

```squirrel
// Reset the BQ25895
batteryCharger.reset();
```

## License ##

This library is licensed under the [MIT License](LICENSE).
