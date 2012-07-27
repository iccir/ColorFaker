/*
    Copyright (c) 2012 Ricci Adams

    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
    LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
    OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
    WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#import "AppDelegate.h"

#import "AdView.h"
#import "BigSwitch.h"

#import <Security/Authorization.h>
#import <ServiceManagement/ServiceManagement.h>


#define sHelperLabel "com.iccir.ColorFakerHelper"


typedef enum : NSInteger {
    StatusTextTypeProgress,
    StatusTextTypeError,
    StatusTextTypeRestart
} StatusTextType;


const UInt8 sColorFakerGenericRGBDesc[] = {
    0x64, 0x65, 0x73, 0x63, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x25, 0x43, 0x6F, 0x6C, 0x6F,
    0x72, 0x46, 0x61, 0x6B, 0x65, 0x72, 0x20, 0x52, 
    0x65, 0x70, 0x6C, 0x61, 0x63, 0x65, 0x6D, 0x65,
    0x6E, 0x74, 0x20, 0x28, 0x47, 0x65, 0x6E, 0x65,
    0x72, 0x69, 0x63, 0x20, 0x52, 0x47, 0x42, 0x29,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x01, 0x00, 0x00, 0x00, 0x00, 0x25, 0x43, 0x6F,
    0x6C, 0x6F, 0x72, 0x46, 0x61, 0x6B, 0x65, 0x72,
    0x20, 0x52, 0x65, 0x70, 0x6C, 0x61, 0x63, 0x65,
    0x6D, 0x65, 0x6E, 0x74, 0x20, 0x28, 0x47, 0x65,
    0x6E, 0x65, 0x72, 0x69, 0x63, 0x20, 0x52, 0x47,
    0x42, 0x29, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00
};


const UInt8 sColorFakerSRGBDesc[] = {
    0x64, 0x65, 0x73, 0x63, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x1E, 0x43, 0x6F, 0x6C, 0x6F,
    0x72, 0x46, 0x61, 0x6B, 0x65, 0x72, 0x20, 0x52,
    0x65, 0x70, 0x6C, 0x61, 0x63, 0x65, 0x6D, 0x65,
    0x6E, 0x74, 0x20, 0x28, 0x73, 0x52, 0x47, 0x42,
    0x29, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x1E, 0x43,
    0x6F, 0x6C, 0x6F, 0x72, 0x46, 0x61, 0x6B, 0x65,
    0x72, 0x20, 0x52, 0x65, 0x70, 0x6C, 0x61, 0x63,
    0x65, 0x6D, 0x65, 0x6E, 0x74, 0x20, 0x28, 0x73,
    0x52, 0x47, 0x42, 0x29, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00
};


@implementation AppDelegate {
    BOOL _needsRestart;
}

@synthesize window            = o_window,
            bigSwitch         = o_bigSwitch,
            infoText          = o_infoText,
            statusText        = o_statusText,
            progressIndicator = o_progressIndicator,
            adView            = o_adView;


#pragma mark -

- (BOOL) _attempToBlessHelper:(NSError * __autoreleasing *)outError
{
    BOOL result = NO;

    AuthorizationItem   item   = { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
    AuthorizationRights rights = { 1, &item };
    AuthorizationFlags  flags  = kAuthorizationFlagDefaults           |
                                 kAuthorizationFlagInteractionAllowed |
                                 kAuthorizationFlagPreAuthorize       |
                                 kAuthorizationFlagExtendRights;

    AuthorizationRef authRef = NULL;
    
    OSStatus status = AuthorizationCreate(&rights, kAuthorizationEmptyEnvironment, flags, &authRef);

    if (status == errAuthorizationSuccess) {
        CFErrorRef cfError = NULL;
        result = SMJobBless(kSMDomainSystemLaunchd, CFSTR( sHelperLabel ), authRef, &cfError);

        if (cfError) {
            NSError *nsError = CFBridgingRelease(cfError);
            if (outError) *outError = nsError;
        }
    }
    
    return result;
}


- (void) _launchHelperWithCommand:(NSString *)command arguments:(NSArray *)arguments
{
    NSError *error = nil;

    if (![self _attempToBlessHelper:&error]) {
        [self _setStatusText:NSLocalizedString(@"Could not launch helper tool.", nil) type:StatusTextTypeError];
        [self _updateSwitchAnimated:YES];
        return;
    }

    xpc_connection_t connection = xpc_connection_create_mach_service(sHelperLabel, NULL, XPC_CONNECTION_MACH_SERVICE_PRIVILEGED);

    xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
        xpc_type_t type = xpc_get_type(event);
        
        if (type == XPC_TYPE_ERROR) {
            [self _setStatusText:NSLocalizedString(@"Could not communicate with helper tool.", nil) type:StatusTextTypeError];
        }
    });

    if (!connection) {
        connection = xpc_connection_create_mach_service(sHelperLabel, NULL, XPC_CONNECTION_MACH_SERVICE_PRIVILEGED);
    }
    
    if (!connection) {
        [self _setStatusText:NSLocalizedString(@"Could not communicate with helper tool.", nil) type:StatusTextTypeError];
        [self _updateSwitchAnimated:YES];
        return;
    }
    
    
    xpc_connection_resume(connection);
    
    xpc_object_t request = xpc_dictionary_create(NULL, NULL, 0);
    
    xpc_dictionary_set_string(request, "command", [command UTF8String]);

    if (arguments) {
        NSData *data = [NSPropertyListSerialization dataWithPropertyList:arguments format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
        if (data) xpc_dictionary_set_data(request, "data", [data bytes], [data length]);
    }

    xpc_connection_send_message_with_reply(connection, request, dispatch_get_main_queue(), ^(xpc_object_t event) {
        _needsRestart = YES;
        [self _updateSwitchAnimated:YES];
        [self _updateStatusText];
    });
}


- (void) _setStatusText:(NSString *)text type:(StatusTextType)type
{
    if (type == StatusTextTypeError) {
        [o_statusText setTextColor:[NSColor redColor]];
        [o_statusText setAlignment:NSCenterTextAlignment];

    } else if (type == StatusTextTypeRestart) {
        [o_statusText setTextColor:[NSColor colorWithDeviceWhite:0.3 alpha:1]];
        [o_statusText setAlignment:NSCenterTextAlignment];
    
    } else {
        [o_statusText setTextColor:[NSColor blackColor]];
        [o_statusText setAlignment:NSLeftTextAlignment];
    }

    [o_statusText setStringValue:(text ? text : @"")];

    if ((type == StatusTextTypeProgress) && [text length]) {
        [o_progressIndicator startAnimation:self];
    } else {
        [o_progressIndicator stopAnimation:self];
    }
}


- (BOOL) _isProfileFaked:(ColorSyncProfileRef)profile
{
    if (!profile) return NO;
    NSString *description = CFBridgingRelease(ColorSyncProfileCopyDescriptionString(profile));
    return ([description rangeOfString:@"ColorFaker"].location != NSNotFound);
}


- (BOOL) _isDiskProfileFaked
{
    NSData *data = [NSData dataWithContentsOfFile:@"/System/Library/ColorSync/Profiles/sRGB Profile.icc"];

    CFErrorRef error = NULL;
    ColorSyncProfileRef profile = ColorSyncProfileCreate((__bridge CFDataRef)data, &error);
    if (error) CFRelease(error);

    BOOL result = [self _isProfileFaked:profile];

    if (profile) CFRelease(profile);

    return result;
}


- (void) _turnOn
{
    NSScreen     *screen = [NSScreen mainScreen];
    NSColorSpace *space  = [screen colorSpace];
    NSData       *genericData;
    NSData       *standardData;

    ColorSyncMutableProfileRef profile = ColorSyncProfileCreateMutableCopy([space colorSyncProfile]);
    ColorSyncProfileRemoveTag(profile, CFSTR("mmod"));
    ColorSyncProfileRemoveTag(profile, CFSTR("dscm"));

    NSData *(^dataWithDescription)(NSData *) = ^(NSData *description) {
        ColorSyncProfileSetTag(profile, CFSTR("desc"), (__bridge CFDataRef)description);

        CFErrorRef error   = NULL;
        CFErrorRef warning = NULL;

        if (!ColorSyncProfileVerify(profile, &error, &warning)) {
            if      (error)   [self _setStatusText:CFBridgingRelease(CFErrorCopyDescription(error))   type:StatusTextTypeError];
            else if (warning) [self _setStatusText:CFBridgingRelease(CFErrorCopyDescription(warning)) type:StatusTextTypeError];
        }

        if (error)   { CFRelease(error);   error   = NULL; }
        if (warning) { CFRelease(warning); warning = NULL; }

        NSData *result = CFBridgingRelease(ColorSyncProfileCopyData(profile, &error));

        if (error)   { CFRelease(error);   error   = NULL; }

        return result;
    };

    genericData  = dataWithDescription([NSData dataWithBytes:sColorFakerGenericRGBDesc length:sizeof(sColorFakerGenericRGBDesc)]);
    standardData = dataWithDescription([NSData dataWithBytes:sColorFakerSRGBDesc       length:sizeof(sColorFakerSRGBDesc)]);

    [self _launchHelperWithCommand:@"profile" arguments: @[ genericData, standardData ] ];

cleanup:
    if (profile) CFRelease(profile);
}


- (void) _turnOff
{
    [self _launchHelperWithCommand:@"revert" arguments:nil];
}


- (void) _updateSwitchAnimated:(BOOL)animated
{
    [o_bigSwitch setOn:[self _isDiskProfileFaked] animated:animated];
}


- (void) _updateStatusText
{
    if (_needsRestart) {
        [self _setStatusText:NSLocalizedString(@"Restart to apply the changes", nil) type:StatusTextTypeRestart];
    } else {
        [self _setStatusText:nil type:StatusTextTypeProgress];
    }
}


#pragma mark -

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSString *infoTextPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"txt"];
    if (infoTextPath) {
        NSError  *error    = nil;
        NSString *infoText = [NSString stringWithContentsOfFile:infoTextPath encoding:NSUTF8StringEncoding error:&error];
        
        if (infoText) {
            [o_infoText setStringValue:infoText];
        }
    }

    [self _updateSwitchAnimated:NO];
    [self _updateStatusText];

    [o_window center];
    [o_window makeKeyAndOrderFront:self];

    [o_adView setTarget:self];
    [o_adView setAction:@selector(purchaseMyColorMeter:)];

    [[NSUserDefaults standardUserDefaults] synchronize];
        
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DidDisplayDisclaimer"]) {
        [self performSelector:@selector(_showAlert:) withObject:nil afterDelay:0.25];
    } else {
        [o_bigSwitch setTarget:self];
        [o_bigSwitch setAction:@selector(handleSwitch:)];
    }
}

- (void) _showAlert:(id)sender
{
    NSString *message = NSLocalizedString(@"Color Faker Disclaimer", nil);
    NSString *agree   = NSLocalizedString(@"Yikes!  I Agree", nil);
    NSString *quit    = NSLocalizedString(@"Quit", nil);

    NSString *infoText = NSLocalizedString(
        @"This software modifies system files, which could result in damage to "
        @"your computer or operating system.\n\n"
        @"In no event shall the authors or copyright holders be "
        @"liable for any claim, damages or other liability, whether in an action "
        @"of contract, tort or otherwise, arising from, out of or in connection "
        @"with the software or the use or other dealings in the software.\n"
    , nil);

    NSAlert *alert = [NSAlert alertWithMessageText:message defaultButton:quit alternateButton:agree otherButton:nil informativeTextWithFormat:@"%@", infoText];
        
    [alert beginSheetModalForWindow:o_window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];

}


- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode == 1) {
        [NSApp terminate:self];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DidDisplayDisclaimer"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        [o_bigSwitch setTarget:self];
        [o_bigSwitch setAction:@selector(handleSwitch:)];
    }
}


- (BOOL) windowShouldClose:(id)sender
{
    [NSApp terminate:self];
    return YES;
}


- (IBAction) handleSwitch:(id)sender
{
    if ([sender isOn]) {
        [self _turnOn];
    } else {
        [self _turnOff];
    }
}


- (IBAction) visitColorFakerOnGitHub:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"http://github.com/iccir/ColorFaker/"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


- (IBAction) purchaseMyColorMeter:(id)sender
{
    NSURL *url = [NSURL URLWithString:@"macappstore://itunes.apple.com/us/app/classic-color-meter/id451640037?mt=12"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}


@end
