For loop parallelism in iOS
===========================

The hardware of iPhone has improved a lot over the years. This enables us, developers, to use the phone more and more as real processing entity. But how can we take full advantage of the hardware? The topic I'm going to discuss is concurrent programing and how to take advantage of the multiple cores of the iPhone.

Problem
-------

Lets say we have a dictionary and our task is to count the palindromic words in it. Incase you don't remember, a palindrome is a word or sentence that reads the same forward as it does backward. Here is a basic approach to the problem:

    FOR EACH wordOne IN dictionary:
        FOR EACH wordTwo IN dictionary:
            IF caseInsensitiveEquals(reverse(wordOne), wordTwo):
                palindromicWordCount++
                
Running this on a single thread may take a long time, so how could this be done faster? Here is the trick, the iterations of the outer loop can be executed independently! Each iteration of the loop can therefor be performed on different threads concurrently. The only code that needs synchronization is the code that increments the word count, this is called the critical section. 

Solution
--------

iOS 4.0 introduced [Grand Central Dispatch][GDC] (GDC), a low level framework that makes it easy to do multithreading and background calculations. On a closer look at the API the following function can be found:

    void dispatch_apply( size_t iterations, dispatch_queue_t queue, void (^block)(size_t));
    
This functions executes the specified block, specified number of times (`iterations`), on the specified queue. The block takes the iteration number as it's argument. This is basically a for loop and is exactly what we need. Finally, `dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)` is used for getting a concurrent queue. And some real code:

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
    
The optimizations made to the pseudo code are left as an exercise to the reader. The synchronization of the critical section is achieved by using the `OSAtomicAdd32` function. This function ensures that the memory is not read while the increment operation is being done.

Results:
--------
The code above was run both concurrently and sequentially. Two dictionaries containing 25143 and 35102 words were used. The device of choice was a brand new iPhone 5.

<table>
    <tr><td># Words</td><td>Execution</td><td>Time</td><td>Speedup</td></tr>
    <tr><td>25143</td><td>Sequential</td><td>388.5</td><td>1.000</td></tr>
    <tr><td>25143</td><td>Concurrent</td><td>208.2</td><td>1.866</td></tr>
    <tr><td>35102</td><td>Sequential</td><td>766.2</td><td>1.000</td></tr>
    <tr><td>35102</td><td>Concurrent</td><td>411.4</td><td>1.862</td></tr>
</table>

As you can see, we are running 1.8 times faster than before. This proves that we are actually using both of the cores. But wait a minute. If we have two cores why aren't we getting 2 times the speed? The reason to this can be explained with Amdahlʼs Law.

Amdahlʼs Law gives us the following formula, Speedup(n) = 1 / [s + (1-s)/ n], where n is the number of processors and s the portion of the program run sequentially. The sequential part of our code is the code executed inside each block. Even if multiple blocks may be executed concurrently the code inside each block is executed sequentially. Lets say for the sake of the argument that the sequential portion of the program in 5% and we have 2 processors. This gives us the formula: 1 / [0.05 + (1 - 0.05)/2] = 1.9, this is the theoretical maximum speedup, an upper bound for how much we can improve. Further, if we had 1024 cores the speedup would be less then 20 times. Amdahlʼs Law gives us an understanding of what we can and can not achieve by using multiple cores. Simply put, the longer it takes for the sequential part of the code, the lesser will each additional core improve the result.

[GDC]: https://developer.apple.com/library/mac/#documentation/Performance/Reference/GCD_libdispatch_Ref/Reference/reference.html