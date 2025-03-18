#import <UIKit/UIKit.h>

@interface NSBundle ()
+ (instancetype)mediaControlsBundle;
+ (instancetype)mediaRemoteUIBundle;
@end

@interface CCUICAPackageDescription : NSObject
- (NSURL *)packageURL;
+ (instancetype)descriptionForPackageNamed:(NSString *)pkg inBundle:(NSBundle *)bundle;
@end

@interface CAStateElement : NSObject
@property (nonatomic, strong, readwrite) CALayer *target;
@property (nonatomic, strong, readonly) NSString *keyPath;
@end

@interface CAStateSetValue : CAStateElement
@property (nonatomic, strong, readwrite) id value;
- (void)setKeyPath:(NSString *)keyPath;
@end

@interface CAState : NSObject
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) BOOL enabled;
@property (nonatomic, strong, readwrite) NSArray *elements;
@end

@interface CALayer ()
@property (nonatomic, strong, readwrite) NSArray *states;
- (CAState *)stateWithName:(NSString *)name;
@end

@interface CAPackage : NSObject
- (CALayer *)rootLayer;
+ (instancetype)ccuiPackageFromDescription:(CCUICAPackageDescription *)desc;
@end

@interface MediaControlsVolumeController : NSObject
- (NSString *)packageNameForRouteType:(NSInteger)routeType isRTL:(BOOL)rtl isSlider:(BOOL)slider;
@end

@interface MediaControlsVolumeViewController : NSObject
- (MediaControlsVolumeController *)volumeController;
@end

@interface MediaControlsAudioModule : NSObject
- (MediaControlsVolumeViewController *)contentViewController;
@end

@interface CCUIModuleInstance : NSObject
// Not actually true
- (MediaControlsAudioModule *)module;
@end

@interface CCUIModuleInstanceManager : NSObject
+ (instancetype)sharedInstance;
- (CCUIModuleInstance *)instanceForModuleIdentifier:(NSString *)mid;
@end

@interface CCUICAPackageView : UIView
- (void)setPackage:(CAPackage *)package;
- (void)setPackageDescription:(CCUICAPackageDescription *)desc;
- (CAPackage *)package;
- (CCUICAPackageDescription *)packageDescription;
- (void)setScale:(CGFloat)scale;
- (CALayer *)packageLayer;
@end

@interface MRUNowPlayingRoutingButton : UIButton
- (CCUICAPackageView *)packageView;
- (NSInteger)deviceType;
- (BOOL)isActive;
- (void)updatePackage;
@end

@interface MRUOutputDeviceAsset : NSObject
- (CCUICAPackageDescription *)packageDescription;
- (NSString *)packageNameForAssetType:(NSInteger)type;
- (NSInteger)type;
@end

@interface MRUSystemOutputDeviceRouteController : NSObject
- (MRUOutputDeviceAsset *)systemOutputDeviceAsset;
+ (instancetype)sharedController;
@end

static void _populateAllShapeSublayers(CALayer *layer, NSMutableArray *arr) {
	NSArray *subs=layer.sublayers;
	//if(!subs)
	//	return;
	for(CALayer *sub in subs) {
		if([sub isMemberOfClass:NSClassFromString(@"CAShapeLayer")])
			[arr addObject:sub];
		if(sub.sublayers)
			_populateAllShapeSublayers(sub, arr);
	}
}

static CCUICAPackageDescription *_getVolumeControllerPackageDesc(NSString **name) {
	static int hasMRURouteController=-1;
	static MRUSystemOutputDeviceRouteController *routeController=nil;
	static MediaControlsVolumeController *controller=nil;
	if(hasMRURouteController==-1) {
		if((routeController=[objc_getClass("MRUSystemOutputDeviceRouteController") sharedController]))
			hasMRURouteController=1;
		else {
			hasMRURouteController=0;
			controller=[%c(MediaControlsVolumeController) new];
		}
	}
	if(hasMRURouteController) {
		MRUOutputDeviceAsset *asset=[routeController systemOutputDeviceAsset];
		//CCUICAPackageDescription *ret=[asset packageDescription];
		//*name=[[[ret packageURL] lastPathComponent] stringByDeletingPathExtension];
		*name=[asset packageNameForAssetType:[asset type]];
		return [%c(CCUICAPackageDescription) descriptionForPackageNamed:*name inBundle:[NSBundle mediaRemoteUIBundle]];
	}
	*name=[controller packageNameForRouteType:0 isRTL:NO isSlider:YES];
	return [%c(CCUICAPackageDescription) descriptionForPackageNamed:*name inBundle:[NSBundle mediaControlsBundle]];
}

%hook MRUNowPlayingRoutingButton

- (void)updatePackage {
	[[self packageView] setPackageDescription:nil];
	return %orig;
}

- (void)updatePackageState {
	if([self deviceType]==0&&[self isActive]) {
		NSString *pkgname;
		CCUICAPackageDescription *pkgdesc=_getVolumeControllerPackageDesc(&pkgname);
		NSString *pkgdescname=[[[[[self packageView] packageDescription] packageURL] lastPathComponent] stringByDeletingPathExtension];
		if(pkgdescname&&[pkgdescname isEqualToString:pkgname]) {
			return %orig;
		}
		[[self packageView] setPackageDescription:pkgdesc];
		CAPackage *package=[[self packageView] package];
		if(!package) {
			return %orig;
		}
		NSMutableArray *layers=[NSMutableArray array];
		CALayer *rootLayer=[package rootLayer];
		_populateAllShapeSublayers(rootLayer,layers);
		//NSMutableArray *scalingOps=[NSMutableArray array];
		NSMutableArray *stateops=[NSMutableArray array];
		for(CALayer *v in layers) {
			CAStateSetValue *ssv=[%c(CAStateSetValue) new];
			[ssv setTarget:v];
			[ssv setKeyPath:@"fillColor"];
			ssv.value=(__bridge id)[UIColor colorWithRed:0.03922 green:0.5176 blue:1 alpha:1].CGColor;
			[stateops addObject:ssv];
			//CAStateSetValue *ssv2=[%c(CAStateSetValue) new];
			//[ssv2 setTarget:v];
			//[ssv2 setKeyPath:@"transform"];
			//ssv2.value=[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.6,0.6,1)];
			//[stateops addObject:ssv2];
			//[scalingOps addObject:ssv2];
		}
		CAState *onState=[%c(CAState) new];
		onState.name=@"on";
		onState.elements=stateops;
		stateops=[NSMutableArray array];
		{
			CAStateSetValue *ssv=[%c(CAStateSetValue) new];
			[ssv setTarget:rootLayer];
			[ssv setKeyPath:@"cornerRadius"];
			ssv.value=@18;
			[stateops addObject:ssv];
		}
		{
			CAStateSetValue *ssv=[%c(CAStateSetValue) new];
			[ssv setTarget:rootLayer];
			[ssv setKeyPath:@"backgroundColor"];
			ssv.value=(__bridge id)[UIColor colorWithRed:0.03922 green:0.5176 blue:1 alpha:1].CGColor;
			[stateops addObject:ssv];
		}
		CAState *onSelectedState=[%c(CAState) new];
		onSelectedState.name=@"on selected";
		onSelectedState.elements=stateops;
		rootLayer.states=@[onState,onSelectedState];
		rootLayer.sublayerTransform=CATransform3DMakeScale(0.7,0.7,1);
		//[[self packageView] setPackageDescription:pkgdesc];
		//[[self packageView] setPackage:package];
		//[[self packageView] setScale:0.6];
		return %orig;
	}else if(![[[[self packageView] package] rootLayer] stateWithName:@"off selected"]) {
		//[[self packageView] setScale:1];
		return [self updatePackage];
	}
	return %orig;
}

%end