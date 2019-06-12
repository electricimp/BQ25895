# BQ25895 2.0.0 #

The library provides a driver for the [BQ25895](https://www.ti.com/lit/ds/symlink/bq25895.pdf) and the [BQ25895M](http://www.ti.com/lit/ds/symlink/bq25895m.pdf) switch-mode battery charge and system power path management devices for single-cell Li-Ion and Li-polymer batteries. Theses ICs support high input voltage fast charging and communicates over an I&sup2;C interface. The BQ25895 and the BQ25895M have different default settings &mdash; please see the [*enable()*](#enablesettings) method for details of the default charge settings.

**Note** When using an impC001 breakout board without a battery connected it is recommended that you always enable the battery charger with BQ25895 default settings. If a battery is connected, please follow [the instructions in the Examples](./Examples/README.md) directory to determine the correct settings for your battery.

**To include this library in your project, add** `#require "BQ25895.device.lib.nut:2.0.0"` **at the top of your device code.**

## Class Usage ##

### Constructor: BQ25895(*i2cBus [,i2cAddress]*) ###

The constructor does not configure the battery charger. It is recommended that either the *enable()* method is called and passed settings for your battery, or the [*disable()*](#disable) method is called immediately after the constructor and on cold boots.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *i2cBus* | imp i2c bus object | Yes | The imp I&sup2;C bus that the BQ25895M is connected to. The I&sup2;C bus **must** be pre-configured &mdash; the library will not configure the bus |
| *i2cAddress* | Integer | No | The BQ25895's I&sup2;C address. Default: 0xD4 |

#### Example ####

```squirrel
#require "BQ25895.device.lib.nut:2.0.0"

// Alias and configure an impC001 I2C bus
local i2c = hardware.i2cKL;
i2c.configure(CLOCK_SPEED_400_KHZ);

// Instantiate a BQ25895 object
batteryCharger <- BQ25895(i2c);
```

## Class Methods ##

### enable(*[settings]*) ###

This method configures and enables the battery charger with settings to perform a charging cycle when a battery is connected and an input source is available. It is recommended that this method is called immediately after the constructor and on cold boots with the settings for your battery.

#### Parameters ####

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *settings* | Table | No | A table of additional settings &mdash; see [**Settings Options**](#settings-options), below |

##### Settings Options #####

| Key | Type | Description |
| --- | --- | --- |
| *BQ25895MDefaults* | Boolean | Whether to enable the charger with defaults for the BQ25895M part. If `true` the *chargeVoltage* is set to `4.352V` and *currentLimit* to `2048mA`. Default: `false` |
| *voltage* | Float | The desired charge voltage in Volts. Range: 3.84-4.608V. Default: 4.208V. **Note** If *BQ25895MDefaults* flag is set to `true`, this value will be ignored |
| *current* | Integer | The desired fast charge current limit in mA. Range: 0-5056mA. Default: 2048mA. **Note** If *BQ25895MDefaults* flag is set to `true`, this value will be ignored |
| *setChargeCurrentOptimizer* | Boolean | Identify maximum power point without overload the input source. Default: `true` |
| *setChargeTerminationCurrentLimit* | Integer | Charge cycle is terminated when battery voltage is above recharge threshold and the current is below *termination current*. Range: 64-1024mA. Default: 256mA |

#### Return Value ####

Nothing.

#### Example ####

```squirrel
// Configure battery charger with default setting for BQ25895
// A charge voltage of 4.208V and current limit of 2048mA.
batteryCharger.enable();
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

### getChargeVoltage() ###

This method gets the connected battery's current charge voltage.

#### Return Value ####

Float &mdash; The charge voltage in V.

#### Example ####

```squirrel
local voltage = batteryCharger.getChargeVoltage();
server.log("Voltage (charge): " + voltage + "V");
```

### getBatteryVoltage() ###

This method gets the current battery voltage based on internal ADC conversion.

#### Return Value ####

Float &mdash; The battery voltage in V.

#### Example ####

```squirrel
local voltage = batteryCharger.getBatteryVoltage();
server.log("Voltage (ADC): " + voltage + "V");
```

### getVBUSVoltage() ###

This method gets the V<sub>BUS</sub> voltage based on ADC conversion. This is the input voltage.

#### Return Value ####

Float &mdash; The V<sub>BUS</sub> voltage in V.

#### Example ####

```squirrel
local voltage = batteryCharger.getVBUSVoltage();
server.log("Voltage (VBAT): " + voltage + "V");
```

### getSystemVoltage() ###

This method gets the system voltage based on the ADC conversion. This the output voltage which can be used to drive other chips in your application. In most impC001-based applications, the system voltage is the impC001 V<sub>MOD</sub> supply.

#### Return Value ####

Float &mdash; The system voltage in V.

#### Example ####

```squirrel
local voltage = batteryCharger.getSystemVoltage();
server.log("Voltage (system): " + voltage + "V");
```

### getChargingCurrent() ###

This method gets the measured current going to the battery.

#### Return Value ####

Integer &mdash; The charging current in mA.

#### Example ####

```squirrel
local current = batteryCharger.getChargingCurrent();
server.log("Current (charging): " + current + "mA");
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
switch(inputStatus.vbusStatus) {
    case BQ25895_VBUS_STATUS.NO_INPUT:
        server.log("No Input");
        break;
    case BQ25895_VBUS_STATUS.USB_HOST_SDP:
        server.log("USB Host SDP");
        break;
    case BQ25895_VBUS_STATUS.USB_CDP:
        server.log("USB CDP");
        break;
    case BQ25895_VBUS_STATUS.USB_DCP:
        server.log("USB DCP");
        break;
    case BQ25895_VBUS_STATUS.ADJUSTABLE_HV_DCP:
        server.log("Adjustable High Voltage DCP");
        break;
    case BQ25895_VBUS_STATUS.UNKNOWN_ADAPTER:
        server.log("Unknown Adapter");
        break;
    case BQ25895_VBUS_STATUS.NON_STANDARD_ADAPTER:
        server.log("Non Standard Adapter");
        break;
    case BQ25895_VBUS_STATUS.OTG:
        server.log("OTG");
        break;
}

server.log("Input Current Limit = " + inputStatus.inputCurrentLimit);
```

### getChargingStatus() ###

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
local status = charger.getChargingStatus();
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
        server.log("Battery charge termination done");
        // Do something
        break;
}
```

### getChargerFaults() ###

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
local faults = batteryCharger.getChargerFaults();
server.log("Fault Report");
if (faults.watchdogFault) server.log("Watchdog Timer Fault reported");
if (faults.boostFault) server.log("Boost Fault reported");

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

if (faults.battFault) server.log("VBAT too high");

switch(faults.ntcFault) {
    case BQ25895_NTC_FAULT.NORMAL:
        server.log("NTC OK");
        break;
    case BQ25895_NTC_FAULT.TS_COLD:
        server.log("NTC NOT OK - TS Cold");
        break;
    case BQ25895_NTC_FAULT.TS_HOT:
        server.log("NTC NOT OK - TS Hot");
        break;
```

### reset() ###

This method provides a software reset which clears all of the BQ25895's register settings.

**Note** This will reset the charge voltage and current to the register defaults. For BQ25895 the defaults are 4.208V and 2048mA. For BQ25895M the defaults are 4.352V and 2048mA. 

#### Return Value ####

Nothing.

#### Example ####

```squirrel
// Reset the BQ25895
batteryCharger.reset();
```

## License ##

This library is licensed under the [MIT License](LICENSE).
