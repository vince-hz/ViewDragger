# ViewDragger

[![Version](https://img.shields.io/cocoapods/v/ViewDragger.svg?style=flat)](https://cocoapods.org/pods/ViewDragger)
[![License](https://img.shields.io/cocoapods/l/ViewDragger.svg?style=flat)](https://cocoapods.org/pods/ViewDragger)
[![Platform](https://img.shields.io/cocoapods/p/ViewDragger.svg?style=flat)](https://cocoapods.org/pods/ViewDragger)

  Setup forwards superView and backwards superView.Then you can drag view backwards and forwards. This is an alternative to modal viewController with transition animation.

  When user drag the animation view, the dragger lifts the view to the window level.When the drag ended, the dragger will place the animation view to the right place.

  All you have to care is the backwards view and forwards view. Also backwards frame and forwards frame needs to be set.

<img src="example.webp">

## Example

```swift
let dragger = ViewDragger(animationView: aView, // the view need drag animation
                          backwardsSuperView: aBackwardsSuperView, // the original superview
                          forwardSuperView: aForwardsSuperView, // forwards animation superview
                          backwardsViewFrame: aBackwardsFrame, // the orginal frame
                          forwardsViewFrame: aForwardsFrame, // forwards animation end frame
                          gestureAxis: .horizontal) // or .vertical
```

## Installation

ViewDragger is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ViewDragger'
```

## License

ViewDragger is available under the MIT license. See the LICENSE file for more info.
