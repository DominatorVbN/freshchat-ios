//
//  FCTemplateDropDownView.h
//  FreshchatSDK
//
//  Created by Hemanth Kumar on 30/03/20.
//  Copyright © 2020 Freshdesk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FCDropDownViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface FCTemplateDropDownView : UIView<FCOutboundDelegate>
@property(nonatomic, strong) FCDropDownViewModel *dropDownViewModel;
@property(nonatomic, weak) id<FCTemplateDelegate> delegate;
@end

NS_ASSUME_NONNULL_END
