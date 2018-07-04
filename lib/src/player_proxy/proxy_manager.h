//
//  proxy_manager.h
//  SparkLib
//
//  Created by alexeym on 26/03/2018.
//  Copyright © 2018 Hola. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "player_proxy.h"

@interface SparkPlayerProxyManager : NSObject
@property NSMutableDictionary<NSValue *, SparkLibProxy *> *proxy_list;
- (SparkLibProxy *)add_player_proxy:(AVPlayerItem *)item
    loader:(SparkLoader *)loader player:(id<SparkLibPlayerDelegate>)player;
- (void)remove_player_proxy:(AVPlayerItem *)item;
- (SparkLibProxy *)get_player_proxy:(AVPlayerItem *)item;
- (void)uninit;
@end
