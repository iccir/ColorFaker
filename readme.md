# ColorFaker

ColorFaker is a small utility that restores pre-10.8 color management behavior on OS X 10.8. 

**<h1>Note: ColorFaker is no longer being developed and is [incompatible](https://github.com/iccir/ColorFaker/issues/1) with OS X 10.10 and higher.</h1>**

## Why?

In OS X 10.8 Mountain Lion, when a color or image lacks an embedded color profile, it is interpreted in the sRGB color space.  Previously, the main display's color space was used.

As a result, color meter utilities will show values after an sRGB → Main Display conversion.  While many meters offer a "Display in sRGB" feature, using it will result in a double conversion.  This results in rounding errors or clipped values.

Color Faker replaces the Generic RGB and sRGB color profiles with the main display's profile.  This allows "native values" in color meters to once again be the native values of the display.

As a side-effect, any "Convert to sRGB" or "Assign sRGB Profile" commands in applications will no longer work.  You will still be able to manually assign the backup sRGB profile.


## Usage

1. [Download ColorFaker](https://github.com/iccir/ColorFaker/downloads) and launch it
2. Turn the giant switch to On
3. There is no step 3


## More Information

For more information about color conversions, you can read my article on [OS X Color Meters and Color Space Conversion](http://iccir.com/articles/osx-color-conversions)
