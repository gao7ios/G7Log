//
//	RKLog -- RestKit, embedded, Gao7Core/G7Log
//
//
//  Created by Blake Watters on 6/10/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "G7Log.h"
#import "G7.h"

@interface G7NSLogLogger : NSObject <G7Logging>
@end

#if G7LOG_USE_NSLOGGER && __has_include("LCLNSLogger_G7.h")
#import "LCLNSLogger_G7.h"
#define G7LOG_CLASS LCLNSLogger_G7

#elif __has_include("G7LumberjackLogger.h")
#import "G7LumberjackLogger.h"
#define G7LOG_CLASS G7LumberjackLogger

#else
#define G7LOG_CLASS G7NSLogLogger
#endif

// Hook into Objective-C runtime to configure logging when we are loaded
@interface G7LogInitializer : NSObject
@end

@implementation G7LogInitializer

+ (void)load
{
	G7lcl_configure_by_name("Gao7Core*", G7LogLevelDefault);
	G7lcl_configure_by_name("App", G7LogLevelDefault);
	if (G7GetLoggingClass() == Nil) G7SetLoggingClass([G7LOG_CLASS class]);
	G7LogInfo(@"Gao7Core logging initialized...");
	
	[G7LogInitializer printLogo];
}

+ (void)printLogo
{
#if TARGET_OS_IPHONE
	fprintf( stderr, "Gao7SDK\n" );
	fprintf( stderr, "[Version]		%s	\n", [G7_CORE_VERSION UTF8String] );
	fprintf( stderr, "[System]		%s	\n", [G7SystemInfo OSVersion].UTF8String );
	fprintf( stderr, "[Device]		%s	\n", [G7SystemInfo deviceModel].UTF8String );
	fprintf( stderr, "[OpenUUID]	%s	\n", [G7SystemInfo openUDID].UTF8String );
	fprintf( stderr, "[G7UUID]		%s	\n", [G7SystemInfo g7udid].UTF8String );
	fprintf( stderr, "[IDFA]		%s	\n", [G7SystemInfo IDFA].UTF8String );
	fprintf( stderr, "[Home]		%s	\n", [NSBundle mainBundle].bundlePath.UTF8String );
	fprintf( stderr, "\n" );
#endif	// #if TARGET_OS_IPHONE
}

@end

static Class <G7Logging> G7LoggingClass;

Class <G7Logging> G7GetLoggingClass(void)
{
	return G7LoggingClass;
}

void G7SetLoggingClass(Class <G7Logging> loggingClass)
{
	G7LoggingClass = loggingClass;
}

@implementation G7NSLogLogger

+ (void)logWithComponent:(_G7lcl_component_t)component
				   level:(_G7lcl_level_t)level
					path:(const char *)file
					line:(uint32_t)line
				function:(const char *)function
				  format:(NSString *)format, ...
{
	va_list args;
	va_start(args, format);
	NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
	va_end(args);
	const char *fileName = (fileName = strrchr(file, '/')) ? fileName + 1 : file;
	NSLog(@"%s %s:%s:%d %@", _G7lcl_level_header[level], _G7lcl_component_header[component], fileName, line, message);
}

@end

int G7LogLevelForString(NSString *, NSString *);

void G7LogConfigureFromEnvironment(void)
{
	static NSString *logComponentPrefix = @"G7LogLevel.";
	
	NSDictionary *envVars = [[NSProcessInfo processInfo] environment];
	
	for (NSString *envVarName in [envVars allKeys]) {
		if ([envVarName hasPrefix:logComponentPrefix]) {
			NSString *logLevel = [envVars valueForKey:envVarName];
			NSString *logComponent = [envVarName stringByReplacingOccurrencesOfString:logComponentPrefix withString:@""];
			logComponent = [logComponent stringByReplacingOccurrencesOfString:@"." withString:@"/"];
			
			const char *log_component_c_str = [logComponent cStringUsingEncoding:NSUTF8StringEncoding];
			int log_level_int = G7LogLevelForString(logLevel, envVarName);
			G7LogConfigureByName(log_component_c_str, log_level_int);
		}
	}
}


int G7LogLevelForString(NSString *logLevel, NSString *envVarName)
{
	// Forgive the user if they specify the full name for the value i.e. "G7LogLevelDebug" instead of "Debug"
	logLevel = [logLevel stringByReplacingOccurrencesOfString:@"G7LogLevel" withString:@""];
	
	if ([logLevel isEqualToString:@"Off"] ||
		[logLevel isEqualToString:@"0"]) {
		return G7LogLevelOff;
	}
	else if ([logLevel isEqualToString:@"Critical"] ||
			 [logLevel isEqualToString:@"1"]) {
		return G7LogLevelCritical;
	}
	else if ([logLevel isEqualToString:@"Error"] ||
			 [logLevel isEqualToString:@"2"]) {
		return G7LogLevelError;
	}
	else if ([logLevel isEqualToString:@"Warning"] ||
			 [logLevel isEqualToString:@"3"]) {
		return G7LogLevelWarning;
	}
	else if ([logLevel isEqualToString:@"Info"] ||
			 [logLevel isEqualToString:@"4"]) {
		return G7LogLevelInfo;
	}
	else if ([logLevel isEqualToString:@"Debug"] ||
			 [logLevel isEqualToString:@"5"]) {
		return G7LogLevelDebug;
	}
	else if ([logLevel isEqualToString:@"Trace"] ||
			 [logLevel isEqualToString:@"6"]) {
		return G7LogLevelTrace;
	}
	else if ([logLevel isEqualToString:@"Default"]) {
		return G7LogLevelDefault;
	}
	else {
		NSString *errorMessage = [NSString stringWithFormat:@"The value: \"%@\" for the environment variable: \"%@\" is invalid. \
								  \nThe log level must be set to one of the following values \
								  \n    Default  or 0 \
								  \n    Critical or 1 \
								  \n    Error    or 2 \
								  \n    Warning  or 3 \
								  \n    Info     or 4 \
								  \n    Debug    or 5 \
								  \n    Trace    or 6\n", logLevel, envVarName];
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:errorMessage userInfo:nil];
		
		return -1;
	}
}

void G7LogIntegerAsBinary(NSUInteger bitMask)
{
	NSUInteger bit = ~(NSUIntegerMax >> 1);
	NSMutableString *string = [NSMutableString string];
	do {
		[string appendString:(((NSUInteger)bitMask & bit) ? @"1" : @"0")];
	} while (bit >>= 1);
	
	NSLog(@"Value of %ld in binary: %@", (long)bitMask, string);
}

void G7LogValidationError(NSError *error)
{
#ifdef _COREDATADEFINES_H
	if ([[error domain] isEqualToString:NSCocoaErrorDomain]) {
		NSDictionary *userInfo = [error userInfo];
		NSArray *errors = [userInfo valueForKey:@"NSDetailedErrors"];
		if (errors) {
			for (NSError *detailedError in errors) {
				NSDictionary *subUserInfo = [detailedError userInfo];
				G7LogError(@"Detailed Error\n \
						   NSLocalizedDescriptionKey:\t\t%@\n \
						   NSValidationKeyErrorKey:\t\t\t%@\n \
						   NSValidationPredicateErrorKey:\t%@\n \
						   NSValidationObjectErrorKey:\n%@\n",
						   [subUserInfo valueForKey:NSLocalizedDescriptionKey],
						   [subUserInfo valueForKey:NSValidationKeyErrorKey],
						   [subUserInfo valueForKey:NSValidationPredicateErrorKey],
						   [subUserInfo valueForKey:NSValidationObjectErrorKey]);
			}
		} else {
			G7LogError(@"Validation Error\n \
					   NSLocalizedDescriptionKey:\t\t%@\n \
					   NSValidationKeyErrorKey:\t\t\t%@\n \
					   NSValidationPredicateErrorKey:\t%@\n \
					   NSValidationObjectErrorKey:\n%@\n",
					   [userInfo valueForKey:NSLocalizedDescriptionKey],
					   [userInfo valueForKey:NSValidationKeyErrorKey],
					   [userInfo valueForKey:NSValidationPredicateErrorKey],
					   [userInfo valueForKey:NSValidationObjectErrorKey]);
		}
		return;
	}
#endif
	G7LogError(@"Validation Error: %@ (userInfo: %@)", error, [error userInfo]);
}

#ifdef _COREDATADEFINES_H
void G7LogCoreDataError(NSError *error)
{
	G7LogToComponentWithLevelWhileExecutingBlock(G7lcl_cGao7Core, G7LogLevelError, ^{
		G7LogValidationError(error);
	});
}
#endif
