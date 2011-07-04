/*
 * Quake3 -- iOS Port
 *
 * Seth Kingsley, August 2009.
 */

#import <Foundation/Foundation.h>
#import <zlib.h>

@interface Q3Downloader : NSObject
{
	id _delegate;
	long long _archiveOffset, _downloadSize, _downloadedBytes, _extractedBytes;
	BOOL _isDecompressing;
	z_stream zstream;
	NSMutableArray *_downloadFiles;
}

@property (assign, readwrite, nonatomic) id delegate;
@property (assign, readwrite, nonatomic) long long archiveOffset;
- (BOOL)addDownloadFileWithPath:(NSString *)path rangeInArchive:(NSRange)range;
- (void)startWithURL:(NSURL *)url;

@end

@interface NSObject (Q3DownloaderDelegate)

- (void)downloader:(Q3Downloader *)downloader didCompleteProgress:(double)progress withText:(NSString *)progressText;
- (void)downloader:(Q3Downloader *)downloader didFinishDownloadingWithError:(NSError *)error;

@end
