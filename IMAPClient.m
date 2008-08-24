#import "IMAPClient.h"

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <stdlib.h>

@implementation IMAPClient
- (NSString*) readLine
{
    NSMutableData* data = [[NSMutableData alloc] init];
    unsigned char c;
    for (;;) {
        recv(socket_, &c, sizeof(c), 0);
        if (c == '\n') {
            NSString* s = [[NSString alloc] initWithData: data
                                                encoding: NSUTF8StringEncoding];
            [data release];
            return [s autorelease];
        } else {
            [data appendBytes: &c length: 1];
        }
    }
    return nil;
}

- (NSArray*) readReply
{
    NSMutableArray* result = [NSMutableArray array];
    NSString* end = [NSString stringWithFormat: @"%d ", number_];
    for (;;) {
        NSString* ln = [self readLine];
        [result addObject: ln];

        if ([ln rangeOfString: end].location == 0) {
            break;
        }
    }
    return result;
}

- (NSArray*) sendCommand: (NSString*) command
{
    number_++;
    NSString* s = [NSString stringWithFormat: @"%d %@\n", number_, command];

    NSData* data = [s dataUsingEncoding: NSUTF8StringEncoding];
    write(socket_, [data bytes], [data length]);

    return [self readReply];
}

- (BOOL) connectToHost: (NSString*) hostname
{
    socket_ = socket(AF_INET, SOCK_STREAM, 0);
    if (socket_ < 0) {
        NSLog(@"socket");
    }

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(143);

    struct hostent* host = gethostbyname([hostname UTF8String]);
    unsigned int** ptr = (unsigned int **) host->h_addr_list;
    while (*ptr != NULL) {
        addr.sin_addr.s_addr = *(*ptr);

        if (connect(socket_, (struct sockaddr *) &addr, sizeof(addr)) == 0) {
            break;
        }

        ptr++;
    }
    if (*ptr == NULL) {
        NSLog(@"connect");
    }

    return [[self readLine] isEqualToString: @"* OK"];
}

- (BOOL) loginWithName: (NSString*) name
              password: (NSString*) password
{
    NSString* str = [NSString stringWithFormat: @"LOGIN %@ %@", name, password];
    [self sendCommand: str];
    return YES;
}

- (void) select: (NSString*) name
{
    NSString* str = [NSString stringWithFormat: @"SELECT %@", name];
    [self sendCommand: str];
}

- (NSArray*) search: (NSString*) spec
{
    NSString* str = [NSString stringWithFormat: @"SEARCH %@", spec];
    return [self sendCommand: str];
}

- (id) init
{
    self = [super init];
    if (! self)
        return nil;

    number_ = 0;

    return self;
}

@end
