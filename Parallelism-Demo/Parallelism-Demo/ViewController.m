// Copyright 2012 Emre Berge Ergenekon
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "ViewController.h"
#include <libkern/OSAtomic.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *outputTextView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *coreChooser;
@end

@implementation ViewController
{
    NSString *_currentFile;
    NSArray *_words;
    int _palindromicWordCount;
    NSTimeInterval _calculationTime;
    dispatch_queue_t _sequentialQueue;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    _sequentialQueue = dispatch_queue_create("Sequential Queue", DISPATCH_QUEUE_SERIAL);
}

- (IBAction)runSmall:(id)sender
{
    _currentFile = @"wordsSmall";
    [self findPalindromicWords];
}

- (IBAction)runMedium:(id)sender
{
    _currentFile = @"wordsMedium";
    [self findPalindromicWords];
}

- (IBAction)runLarge:(id)sender
{
    _currentFile = @"wordsBig";
    [self findPalindromicWords];
}

- (void)findPalindromicWords
{
    [self loadWords];
    
    _palindromicWordCount = 0;
    
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    dispatch_apply(_words.count, [self queue], ^(size_t index) {
        NSString *word = [_words objectAtIndex:index];
        NSString *reverseString = [self reverseString:word];
        
        if ([self string:word isCaseInsensitiveEqualsToString:reverseString]) {
            // Reverse is it self palindromic
            OSAtomicIncrement32(&_palindromicWordCount);
        } else {
            // If the last word is palindromic it's allready been found.
            for (int i = index + 1; i < _words.count -1; i++) {
                if ([self string:reverseString isCaseInsensitiveEqualsToString:[_words objectAtIndex:i]]) {
                    // Both are palindromic
                    OSAtomicAdd32(2, &_palindromicWordCount);
                }
            }
        }
    });
    
    _calculationTime = CFAbsoluteTimeGetCurrent() - startTime;
    
    [self printResults];
}

- (dispatch_queue_t) queue
{
    if ([self isRunSequentially]) {
        NSLog(@"Running sequentially");
        return _sequentialQueue;
    } else {
        NSLog(@"Running concurrently");
        return  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    }
}

- (BOOL)isRunSequentially
{
    return self.coreChooser.selectedSegmentIndex == 0;
}


- (NSString*)reverseString:(NSString*)string {
    int length = [string length];
    NSMutableString *reversedString = [NSMutableString stringWithCapacity:length];
    
    while (length--)
        [reversedString  appendFormat:@"%C", [string characterAtIndex:length]];
    
    return reversedString;
}

- (BOOL) string:(NSString *) aString isCaseInsensitiveEqualsToString:(NSString *) anOtherString
{
    return [aString caseInsensitiveCompare:anOtherString] == NSOrderedSame;
}

- (void) printResults
{
    self.outputTextView.text = @"";
    self.outputTextView.text = [self.outputTextView.text stringByAppendingFormat:@"Iterated %d words\n", _words.count];
    self.outputTextView.text = [self.outputTextView.text stringByAppendingFormat:@"Found %d palindromic words\n", _palindromicWordCount];
    self.outputTextView.text = [self.outputTextView.text stringByAppendingFormat:@"The search took %.1f seconds\n", _calculationTime];
    self.outputTextView.text = [self.outputTextView.text stringByAppendingFormat:@"The search was done %@\n", [self isRunSequentially]? @"sequentially" : @"concurrently"];
}

- (void)loadWords
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:_currentFile ofType:@""];
    NSString *fileContent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    NSMutableArray *words = [NSMutableArray array];
    [fileContent enumerateLinesUsingBlock:^(NSString *word, BOOL *stop) {
        [words addObject:word];
    }];
    _words = [words copy];
}


@end
