//
//  main.m
//  SIP-objc
//
//  Created by Emilio P Egido on 26/2/25.
//  Based on Mykola's blog (https://khronokernel.com/macos/2022/12/09/SIP.html)
//
// Objective-C file to access a function inside /usr/lib/libSystem.dylib

#import <Foundation/Foundation.h>
#import "ObjCSIP.h"
#include <dlfcn.h> // to use dlopen and dlclose

@implementation ObjCSIP

// Method to return SIP value
- (long) sipValue {
        
        NSString *sip_path = @"/usr/lib/libSystem.dylib"; // path to the library
        NSString *sip_function = @"csr_get_active_config"; // function inside dylib

        // Get the function pointer
        void *libSystem = dlopen(sip_path.UTF8String, RTLD_LAZY);
        if (!libSystem) {
            NSLog(@"Error loading libSystem.dylib");
            return -1;
        };

        void *csr_get_active_config = dlsym(libSystem, sip_function.UTF8String);
        if (!csr_get_active_config) {
            NSLog(@"Error loading csr_get_active_config");
            return -1;
        };

        // Call the function
        int (*csr_get_active_config_ptr)(uint32_t *) = (int (*)(uint32_t *))csr_get_active_config;
        uint32_t sip_int = 0;
        int err = csr_get_active_config_ptr(&sip_int);
        if (err) {
            NSLog(@"Error calling csr_get_active_config");
            return -1;
        };

        dlclose(libSystem);

        //NSLog(@"Current SIP value in decimal: %d", sip_int);
        
        //NSLog(@"Current SIP value in hexadecimal: 0x%02x", (sip_int));
        
        return sip_int;
        
}

@end
