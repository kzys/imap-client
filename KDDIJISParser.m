#import "KDDIJISParser.h"

enum {
    ASCII = 0,
    JIS_X_0201_1976,
    JIS_X_0208_1978,
    JIS_X_0208_1983,
};
static char* ESCAPE_SEQUENCES[] = {
    "\e(B", "\e(J", "\e$@", "\e$B"
};

@implementation KDDIJISParser

- (id) emoticonFrom: (unsigned int) n
{
    return [NSString stringWithFormat: @"[%x]", n];
}

- (NSArray*) parse: (NSData*) src
{
    NSMutableArray* result = [NSMutableArray array];

    const unsigned char* bytes = [src bytes];

    int charset = ASCII;

    size_t i = 0, start = 0;
    while (i < [src length]) {
        if (bytes[i] == '\e' && i+2 < [src length]) {
            if (bytes[i+1] == '(' && bytes[i+2] == 'B') {
                charset = ASCII;
            }
            else if (bytes[i+1] == '(' && bytes[i+2] == 'J') {
                charset = JIS_X_0201_1976;
            }
            else if (bytes[i+1] == '$' && bytes[i+2] == '@') {
                charset = JIS_X_0208_1978;
            }
            else if (bytes[i+1] == '$' && bytes[i+2] == 'B') {
                charset = JIS_X_0208_1983;
            }
        }

        if (charset != ASCII && 0x75 <= bytes[i] && bytes[i] <= 0x7b &&
            i+1 < [src length] &&
            0x2a <= bytes[i+1] && bytes[i+1] <= 0x79) {

            NSMutableData* data = [NSMutableData data];
            if (start > 0) {
                char* seq = ESCAPE_SEQUENCES[charset];
                [data appendBytes: seq length: strlen(seq)];
            }
            [data appendBytes: bytes + start
                       length: i - start];
            NSString* str = [[NSString alloc] initWithData: data
                                                  encoding: NSISO2022JPStringEncoding];
            [result addObject: [str autorelease]];

            [result addObject: [self emoticonFrom: bytes[i] << 8 | bytes[i+1] ]];

            i += 2;
            start = i;
        }
        else {
            i++;
        }
    }
    return result;
}
@end
