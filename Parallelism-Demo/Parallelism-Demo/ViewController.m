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

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextView *outputTextView;
@end

@implementation ViewController
{
    NSString *_currentFile;
    NSArray *_words;
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

}

- (void)loadWords
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:_currentFile ofType:@""];
    NSString *fileContent = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    self.outputTextView.text = fileContent;
    NSMutableArray *words = [NSMutableArray array];
    [fileContent enumerateLinesUsingBlock:^(NSString *word, BOOL *stop) {
        [words addObject:word];
    }];
    _words = [words copy];
}


@end
