#import <Foundation/Foundation.h>
#import <IFBKThirtySeven/IFBKThirtySeven.h>
#import "IFBKRoomUsersTracker.h"

@protocol IFBKRoomControllerDelegate;

/**
 * TODO: This class is a kitchen sink.
 * TODO: Retain cycles in blocks.
 * TODO: Support polling as streaming requires the authorization token.
 */
@interface IFBKRoomController : NSObject

/**
 * The designated initializer.
 */
- (id)initWithRoomID:(NSNumber *)roomID authorizationToken:(NSString*)authorizationToken;

/**
 * The ID of the room that this controller will manager.
 */
@property (copy, readonly) NSNumber* roomID;

///-----------------------------------------------------------------------------
/// Configuration
///-----------------------------------------------------------------------------

@property id<IFBKRoomControllerDelegate> delegate;

@property IFBKCampfireClient *apiClient;

/**
 * The Authorization toke for the room, found in the My Info section of the
 * campfire web interface. Requred for the streaming support.
 */
@property (copy, readonly) NSString *authorizationToken;

///-----------------------------------------------------------------------------
/// Properties
///-----------------------------------------------------------------------------

@property (strong, readonly) IFBKCFRoom *room;

@property (copy, readonly) NSNumber *userID;

@property (strong, readonly) NSMutableArray* messages;

///-----------------------------------------------------------------------------
/// Trackers
///-----------------------------------------------------------------------------

@property IFBKRoomUsersTracker *userTracker;

///-----------------------------------------------------------------------------
/// Actions
///-----------------------------------------------------------------------------

- (void)joinRoom;

- (void)leaveRoom;

- (void)postMessage:(NSString*)body;

- (void)refreh;

///-----------------------------------------------------------------------------
/// Unread messages // TODO: Factor out in IFBKRoomMessagesTracker!
///-----------------------------------------------------------------------------

@property BOOL trackUnreadMessages;

@property (assign, readonly) NSUInteger unreadMessagesCount;

@property (copy, readonly) NSNumber* lastReadMessageID;

@property (copy, readonly) NSDate* lastReadMessageDate;

- (void)clearUnreadMessages;

- (BOOL)isMessageUnread:(NSString*)messageID;

@end

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

/**
 */
@protocol IFBKRoomControllerDelegate <NSObject>
- (void)roomControllerDidJoinRoom:(IFBKRoomController*)controller;
- (void)roomController:(IFBKRoomController*)controller didReceiveAlternativeView:(NSView*)view message:(IFBKCFMessage*)message;
- (void)roomController:(IFBKRoomController*)controller didReceiveNewMessage:(IFBKCFMessage*)message;
- (void)roomControllerDidUpdateMessagesList:(IFBKRoomController*)controller;
- (void)roomController:(IFBKRoomController*)controller didConfirmPost:(NSString*)body message:(IFBKCFMessage*)message;

- (void)roomControllerDidUpdateUnreadMessages:(IFBKRoomController*)controller;
- (void)roomController:(IFBKRoomController*)controller didEncouterError:(NSError*)error;
- (void)roomController:(IFBKRoomController*)controller didEncouterStreamError:(NSError*)error;

@end
