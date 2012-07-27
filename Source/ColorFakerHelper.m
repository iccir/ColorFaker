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

#import <Foundation/Foundation.h>

#include <syslog.h>
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h> 
#include <xpc/xpc.h>

static NSString *sExtraBackupSRGBProfilePath       = @"/Library/ColorSync/.ColorFaker_sRGB_backup";
static NSString *sExtraBackupGenericRGBProfilePath = @"/Library/ColorSync/.ColorFaker_GenericRGB_backup";

static NSString *sBackupSRGBProfilePath            = @"/Library/ColorSync/Profiles/sRGB Backup Profile.icc";
static NSString *sBackupGenericRGBProfilePath      = @"/Library/ColorSync/Profiles/Generic RGB Backup Profile.icc";

static NSString *sSystemSRGBProfilePath            = @"/System/Library/ColorSync/Profiles/sRGB Profile.icc";
static NSString *sSystemGenericRGBProfilePath      = @"/System/Library/ColorSync/Profiles/Generic RGB Profile.icc";

static const NSInteger GenericError = 1;


static void sFixPermissions(void)
{
    const char *srgbPath = [sSystemSRGBProfilePath UTF8String];
    chown(srgbPath, 0, 0);
    chmod(srgbPath, 0644);

    const char *genericPath = [sSystemGenericRGBProfilePath UTF8String];
    chown(genericPath, 0, 0);
    chmod(genericPath, 0644);
}


static NSInteger sDoProfileCommand(NSArray *arguments)
{
    if (![arguments isKindOfClass:[NSArray class]]) {
        return GenericError;
    }
    
    if ([arguments count] != 2) {
        return GenericError;
    }
    
    NSData *genericProfile  = [arguments objectAtIndex:0];
    NSData *standardProfile = [arguments objectAtIndex:1];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error = nil;

    if (![[NSFileManager defaultManager] fileExistsAtPath:sExtraBackupSRGBProfilePath]) {
        [manager copyItemAtPath:sSystemSRGBProfilePath toPath:sExtraBackupSRGBProfilePath error:&error];
    }

    if (![[NSFileManager defaultManager] fileExistsAtPath:sExtraBackupGenericRGBProfilePath]) {
        [manager copyItemAtPath:sSystemGenericRGBProfilePath toPath:sExtraBackupGenericRGBProfilePath error:&error];
    }
    
    if (![manager fileExistsAtPath:sBackupSRGBProfilePath]) {
        [manager copyItemAtPath:sExtraBackupSRGBProfilePath toPath:sBackupSRGBProfilePath error:&error];
    }

    if (![manager fileExistsAtPath:sBackupGenericRGBProfilePath]) {
        [manager copyItemAtPath:sExtraBackupGenericRGBProfilePath toPath:sBackupGenericRGBProfilePath error:&error];
    }

    BOOL didWrite = [standardProfile writeToFile:sSystemSRGBProfilePath       atomically:YES] &&
                    [genericProfile  writeToFile:sSystemGenericRGBProfilePath atomically:YES];
    
    sFixPermissions();

    return didWrite ? noErr : GenericError;
}


static NSInteger sDoRevertCommand()
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error = nil;
    BOOL didRevert = NO;

    if ([manager fileExistsAtPath:sExtraBackupSRGBProfilePath]) {
        [manager removeItemAtPath:sSystemSRGBProfilePath error:&error];
        didRevert = [manager copyItemAtPath:sExtraBackupSRGBProfilePath toPath:sSystemSRGBProfilePath error:&error];
    }

    if ([manager fileExistsAtPath:sExtraBackupGenericRGBProfilePath]) {
        [manager removeItemAtPath:sSystemGenericRGBProfilePath error:&error];
        didRevert = [manager copyItemAtPath:sExtraBackupGenericRGBProfilePath toPath:sSystemGenericRGBProfilePath error:&error];
    }

    if ([manager fileExistsAtPath:sBackupSRGBProfilePath]) {
        [manager removeItemAtPath:sBackupSRGBProfilePath error:&error];
    }

    if ([manager fileExistsAtPath:sBackupGenericRGBProfilePath]) {
        [manager removeItemAtPath:sBackupGenericRGBProfilePath error:&error];
    }
    
    sFixPermissions();

    return didRevert ? GenericError :noErr;
}


static void sPeerEventHandler(xpc_connection_t connection, xpc_object_t event)
{
	xpc_type_t type = xpc_get_type(event);
    
	if (type != XPC_TYPE_ERROR) {
        NSString *command = nil;
        
        size_t dataLength;
        const void *dataBytes = xpc_dictionary_get_data(event, "data", &dataLength);
        const char *cString   = xpc_dictionary_get_string(event, "command");
        
        if (!cString) {
            NSLog(@"ColorFakerHelper: sPeerEventHandler(): cString is NULL");
            return;
        }
        
        if (cString) {
            command = [[NSString alloc] initWithCString:cString encoding:NSUTF8StringEncoding];
        }

        NSError *error = nil;
        NSArray *arguments = nil;
        
        if (dataBytes) {
            NSData *data = [[NSData alloc] initWithBytes:dataBytes length:dataLength];
            arguments = [NSPropertyListSerialization propertyListWithData:data options:0 format:NULL error:&error];
            [data release];
        }

        NSInteger err = 0;

        if ([command isEqualToString:@"profile"]) {
            err = sDoProfileCommand(arguments);
        } else if ([command isEqualToString:@"revert"]) {
            err = sDoRevertCommand();
        }
        xpc_connection_t remote = xpc_dictionary_get_remote_connection(event);
        
        xpc_object_t reply = xpc_dictionary_create_reply(event);
        xpc_dictionary_set_int64(reply, "result", err);
        xpc_connection_send_message(remote, reply);
        xpc_release(reply);
        
        if (command) [command release];

	} else {
        NSLog(@"ColorFakerHelper: sPeerEventHandler() received error event");
    }
}


static void sConnectionHandler(xpc_connection_t connection)
{
	xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
		sPeerEventHandler(connection, event);
	});
	
	xpc_connection_resume(connection);
}


int main(int argc, char *argv[])
{
@autoreleasepool
{
    xpc_connection_t service = xpc_connection_create_mach_service("com.iccir.ColorFakerHelper", dispatch_get_main_queue(), XPC_CONNECTION_MACH_SERVICE_LISTENER);
    
    if (!service) {
        syslog(LOG_NOTICE, "xpc_connection_create_mach_service() failed");
        exit(1);
    }
    
    xpc_connection_set_event_handler(service, ^(xpc_object_t connection) {
        sConnectionHandler(connection);
    });
    
    xpc_connection_resume(service);
    
    dispatch_main();

    xpc_release(service);
}
    return 0;
}

