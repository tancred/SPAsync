//
//  main.m
//  Racer
//
//  Created by Malte Tancred on 2013-12-18.
//  Public domain
//

#import <Foundation/Foundation.h>
#import <SPAsync/SPAsync.h>
#import <libkern/OSAtomic.h>

// Exercise task creation

@interface Racer : NSObject
- (void)begin;
@end

int main(int argc, const char * argv[])
{
	@autoreleasepool {
		Racer *racer = [Racer new];
		[racer begin];
		//[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2.0]];
	}
    return 0;
}

@implementation Racer

- (void)begin {
	dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_group_t group = dispatch_group_create();

	int64_t doCount = 10000;
	__block int64_t thenCount = 0;

	NSLog(@"scheduling a bunch of tasks");

	for (int64_t i=0; i<doCount; i++) {
		[[self doSomethingOnQueue:q group:group] then:^id(id value) {
			OSAtomicIncrement64(&thenCount);
			return nil;
		} on:q];
	}

	NSLog(@"waiting for the initial tasks to complete");

	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
	dispatch_release(group);

	if (thenCount != doCount) {
		NSLog(@"waiting a while for the 'then' blocks to complete (leap of faith)");
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2.0]];
	}

	if (thenCount == doCount)
		NSLog(@"All 'then' blocks called");
	else
		NSLog(@"expected %lld 'then' blocks, saw %lld", doCount, thenCount);
}

- (SPTask *)doSomethingOnQueue:(dispatch_queue_t)q group:(dispatch_group_t)group {
	SPTaskCompletionSource *ts = [[SPTaskCompletionSource alloc] init];

	//NSLog(@"doing something");

	dispatch_group_async(group, q, ^{
		//NSLog(@"doing something completed");
		[ts completeWithValue:nil];
	});

	return [ts task];
}

@end
