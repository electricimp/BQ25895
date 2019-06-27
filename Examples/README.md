# Setting Up The BQ25895 Library For Your Battery #

## Important Battery Parameters ##

In order to set up the BQ25895/BQ25895M battery charger properly there are two important parameters that you need know for your specific battery: the charging voltage and the charging current limit.

**Note** The new BQ25895 library supersedes the BQ25895M library, which is now deprecated and will not be maintained. We strongly recommend that you update to the the new library, but please be aware that this incorporates a **breaking change** which you will need to accommodate: the default settings have been updated and you may need to change your code accordingly.

## Finding Charging Parameters ##

In this example we will be looking at this [3.7V 2000mAh](https://www.adafruit.com/product/2011?gclid=EAIaIQobChMIh7uL6pP83AIVS0sNCh1NNQUsEAQYAiABEgKFA_D_BwE) battery from Adafruit. This battery is labelled 3.7V but this is the nominal voltage and not the voltage required for charging. The label also shows its capacity to be 2000mAh but provides no specific charging current. This is not enough information to determine our charging parameters so we must look for more information in the battery's [datasheet](LiIon2000mAh37V.pdf).

In Section 3, Form 1 there is a table describing the battery's rated performance characteristics. Looking at the fourth row of the table, we can see the charging voltage is 4.2V. Row six shows the quick charge current is 1CA. The C represents the battery capacity. Row 1 shows that the capacity is 2000mAh. This means that the quick charge current = 1 * 2000mA = 2000mA.

It is very important to find the correct values for these two parameters as exceeding them can damage your battery.

## Default Settings ##

The library provides default settings for the two supported chargers. For the BQ25895, the defaults are 4.208V and 2048mA. For the BQ25895M, the defaults are 4.352V and 2048mA.

As you can see, the default settings for the BQ25895M are not compatible with the example battery, which requires settings of 4.2V and 2000mAh, as we determined above. Therefore if your impC001 breakout board is fitted with this part it is very important to enable the battery with the correct settings as soon as the device boots. You do this by as follows:

```squirrel
/*********** WORKING WITH THE BQ25895M **********
 ***********  AND LiPo 80360 BATTERY   **********/

// Import the BQ25895 driver
#require "BQ25895.device.lib.nut:3.0.0"

// Choose an impC001 I2C bus and configure it
local i2c = hardware.i2cKL;
i2c.configure(CLOCK_SPEED_400_KHZ);

// Instantiate a BQ25895 object
batteryCharger <- BQ25895(i2c);

// Configure the charger to charge at 4.2V to a maximum of 2000mA
local settings = { "voltage" : 4.2,
                   "current" : 2000 };
batteryCharger.enable(settings);
```

The example battery is, however, compatible with the default settings for the BQ25895, so it would also be acceptable to use the BQ25895 defaults when enabling this battery:

```squirrel
/*********** WORKING WITH THE BQ25895 **********
 ***********  AND LiPo 80360 BATTERY   **********/

// Import the BQ25895 driver
#require "BQ25895.device.lib.nut:3.0.0"

// Choose an impC001 I2C bus and configure it
local i2c = hardware.i2cKL;
i2c.configure(CLOCK_SPEED_400_KHZ);

// Instantiate a BQ25895 object
batteryCharger <- BQ25895(i2c);

// Configure the charger to charge at 4.208V to a maximum of 2048mA;
batteryCharger.enable();
```
