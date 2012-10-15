# TweetySenses
===
*Tune your senses to the Twitter Sphere using positional/3D audio*

TweetySenses is a simple application that lets you experience your local environment through twitter. The application will use your current location to to be notified of tweets coming from close by. When TweetySenses receives a tweet, it will use the compas in your iphone to compute the relative location of the tweet. It will then play a sound using positional audio, such that you can actually hear where the tweet came from and how far away it was. But wait! theres more! The sound of tweets from users with few followers will sound thin and high pitched, while the sound of important twitter users will sound deep, low pitched and robust! 

The motivation for this app was to try to extend our limited sense of hearing by allowing humans to tune into a realtiy that is always present around us, yet that we cannot sense. However, due to time constraints, and lack of any percieved financial benefit or public utility, I have decided to stop development.


# How the code is organized

## `WFBSynth`
The bulk of the audio code can be found in the "Synth" group. The `WFBSynth` handles audio rendering, audio session, and provides an api based primarily around a single method that will allow you to play a sound with a string identifier, and provide the playbackRate (it says "pitch", but it is actualy playback rate), azimuth, and distance. 

## `WFBSoundSourceManager`
The sound source manager's responsibility is simply to provide a list of the sounds it finds in the `tweetsounds` directory, and provide an interface for loading those sounds in and out of memory.

## `WFBTwitterStream`
This class has the responsibility of connecting to the streaming API, and forwarding the tweets to an implementor of the `TwitterStreamListener` protocol. It provides an error message when the user does not have a twitter account registered on the device. The `WFBTwitterStream` will also kindly parse tweets into an NSDictionary which it will deliver to its delegate.

## `WFBViewController`
The view controller class became a little awkward due to the fact that everything has to be asynchronously (connection to twitter, aquiring GPS lock) yet still need to be completed in sequence. In order to try to organized several asynchronous calls, I used the NSNotificationCenter to handle the events, update state accordingly, and fire off the next async call

## License / Copyright or whatever
I really hope someone will pick up this project and make a killer app, I think a designer could really make it pop, and maybe even make it worth a go in the App Store. All I ask is that if you use the project, you credit me in some public fashion when you publish to the app store. If someone wants to work together with me on it to developer further, I might be interested.

William Barksdale
wfbarksdale@gmail.com
www.williambarksdale.com
