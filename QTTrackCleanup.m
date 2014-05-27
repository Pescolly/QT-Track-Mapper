//
//  QTTrackCleanup.m
//
//

/*
 QTTrackCleanup is a Cocoa command line tool to set the channel assignments
 for each of 8 audio tracks to specific settings and delete any text tracks.
 */


#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <QuickTime/QuickTime.h>
#import <QTKit/QTKit.h>



#ifndef fieldOffset
#define fieldOffset(type, field) ((size_t) &((type *) 0)->field)
#endif


/*
 Iterates through each text track in theMovie and deletes it.
 */
void deleteTextTracks (Movie theMovie) {
	Track myTrack = NULL;
	
	myTrack = GetMovieIndTrackType(theMovie, 1, TextMediaType, movieTrackMediaType);
	while (myTrack != NULL) {
		//QTUtils_DeleteAllReferencesToTrack (myTrack);
		DisposeMovieTrack(myTrack);
		myTrack = GetMovieIndTrackType(theMovie, 1, TextMediaType, movieTrackMediaType);
	}
}


int main (int argc, const char * argv[]) 
{
	// define audio channel label array
	int fourChanLabels[] = 
	{
		kAudioChannelLabel_LeftTotal,
		kAudioChannelLabel_RightTotal,
		kAudioChannelLabel_LeftTotal,
		kAudioChannelLabel_RightTotal
	};
	
	int channelLabels[] = 
	{
		kAudioChannelLabel_Left, 
		kAudioChannelLabel_Right,
		kAudioChannelLabel_Center,
		kAudioChannelLabel_LFEScreen,
		kAudioChannelLabel_LeftSurround,
		kAudioChannelLabel_RightSurround,
		kAudioChannelLabel_LeftTotal,
		kAudioChannelLabel_RightTotal,
		kAudioChannelLabel_LeftTotal,
		kAudioChannelLabel_RightTotal
	};
	
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSArray *args = [[NSProcessInfo processInfo] arguments];
	if (argc < 2) 
	{
		NSLog(@"**Error** Usage: qttrackcleanup sourceFile");
		return 1;
	}
	NSString *sourceFilePath = [args objectAtIndex:1];
	if (![[NSFileManager defaultManager] fileExistsAtPath:sourceFilePath]) 
	{
		NSLog(@"**Error** Input File doesn't exist");
		return 1;
	}		
	QTMovie *movie = [QTMovie movieWithFile:sourceFilePath error:nil];
	if (!movie) 
	{
		NSLog(@"**Error** Problems opening file");
		return 1;
	}
	Movie qtMovie = [movie quickTimeMovie];	
	
	int audioTrackCounter = 0;
	for (int currentTrack = 1; currentTrack <= 10; currentTrack++) {
		Track audioTrack = GetMovieIndTrackType(qtMovie, currentTrack, SoundMediaType, movieTrackMediaType);
		if (audioTrack == NULL) 
		{
			// get number of audio tracks
			break;
		}
		
		audioTrackCounter++;
	}
	
	NSLog(@"Tracks: %i", audioTrackCounter);
	// Some problem with QTKit and -tracks on a QTMovie. Bus Error.
	// So drop down into the native QuickTime API	
	if (audioTrackCounter == 4)
	{
		for (int currentTrack = 1, audioTrackCounter = 0; currentTrack <= 4; currentTrack++) 
		{
			
			Track audioTrack = GetMovieIndTrackType(qtMovie, currentTrack, SoundMediaType, movieTrackMediaType);
			if (audioTrack == NULL) 
			{
				// remove any text tracks, if they exist
				deleteTextTracks(qtMovie);
				// Save the movie to disk
				[movie updateMovieFile];
				
				return 0;
			}		
			
			AudioChannelLayout* trackChannelLayout = NULL;
			OSStatus err = noErr;	
			UInt32 trackChannelLayoutSize;
			
			// Allocate a layout of the required size
			trackChannelLayoutSize = fieldOffset(AudioChannelLayout, mChannelDescriptions[1]);
			trackChannelLayout = (AudioChannelLayout*)calloc(1, trackChannelLayoutSize);
			trackChannelLayout->mChannelLayoutTag = kAudioChannelLayoutTag_UseChannelDescriptions;
			
			// 1 audio channel per track
			trackChannelLayout->mNumberChannelDescriptions = 1;				
			trackChannelLayout->mChannelDescriptions[0].mChannelLabel = fourChanLabels[audioTrackCounter];
			audioTrackCounter++;
			
			// Set the track layout
			err = QTSetTrackProperty(audioTrack, 
									 kQTPropertyClass_Audio,
									 kQTAudioPropertyID_ChannelLayout, 
									 trackChannelLayoutSize, 
									 trackChannelLayout);
			if (err != noErr) 
			{
				NSLog(@"**Error** QuickTime SetPropertyError: %i", err);
				return 1;
			}		
			
			//printf("labeled audio track %d as %s\n", currentTrack, channelLabels[audioTrackCounter]);
		}
	} else {
			
	// loop through audio tracks
		for (int currentTrack = 1, audioTrackCounter = 0; currentTrack <= 10; currentTrack++) 
		{
			
			Track audioTrack = GetMovieIndTrackType(qtMovie, currentTrack, SoundMediaType, movieTrackMediaType);
			if (audioTrack == NULL) 
			{
				// remove any text tracks, if they exist
				deleteTextTracks(qtMovie);
				// Save the movie to disk
				[movie updateMovieFile];
				
				return 0;
			}		
			
			AudioChannelLayout* trackChannelLayout = NULL;
			OSStatus err = noErr;	
			UInt32 trackChannelLayoutSize;
			
			// Allocate a layout of the required size
			trackChannelLayoutSize = fieldOffset(AudioChannelLayout, mChannelDescriptions[1]);
			trackChannelLayout = (AudioChannelLayout*)calloc(1, trackChannelLayoutSize);
			trackChannelLayout->mChannelLayoutTag = kAudioChannelLayoutTag_UseChannelDescriptions;
			
			// 1 audio channel per track
			trackChannelLayout->mNumberChannelDescriptions = 1;				
			trackChannelLayout->mChannelDescriptions[0].mChannelLabel = channelLabels[audioTrackCounter];
			audioTrackCounter++;
			
			// Set the track layout
			err = QTSetTrackProperty(audioTrack, 
									 kQTPropertyClass_Audio,
									 kQTAudioPropertyID_ChannelLayout, 
									 trackChannelLayoutSize, 
									 trackChannelLayout);
			if (err != noErr) 
			{
				NSLog(@"**Error** QuickTime SetPropertyError: %i", err);
				return 1;
			}		

			//printf("labeled audio track %d as %s\n", currentTrack, channelLabels[audioTrackCounter]);

		}
	}
	
	// make sure there were ONLY 8 audio tracks
	Track audioTrack = GetMovieIndTrackType(qtMovie, 11, SoundMediaType, movieTrackMediaType);
	if (audioTrack != NULL) {
		NSLog(@"**Error** There are more than 10 audio tracks in the input file.");
		return 1;
	}		
	
	
	// remove any text tracks, if they exist
	deleteTextTracks(qtMovie);
	
	// Save the movie to disk
	[movie updateMovieFile];
	
	[pool release];
    return 0;
}


