#import <Foundation/Foundation.h>

@interface IMAPClient : NSObject {
    int socket_;
    int number_;
}
- (BOOL) connectToHost: (NSString*) host;
- (BOOL) loginWithName: (NSString*) name
              password: (NSString*) password;
- (void) select: (NSString*) name;
- (NSArray*) search: (NSString*) spec;
@end
