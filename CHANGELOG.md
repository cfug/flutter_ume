# Changelog

[简体中文](./CHANGELOG_cn.md)

# 5.1.0

- Add customizable floating button size with `floatingButtonSize` parameter
- Improve UMEWidget API with better semantic naming

# 5.0.1

- 更新依赖版本

# 5.0.0

- 全新浮动面板设计
- 面板关闭动画：收缩成圆形并移动到浮动按钮位置
- Logo 图标切换动画效果
- 增加部分 API 函数

# 4.4.2

增加部分回调函数

# 4.4.1

添加缺失的定义

# 4.4.0

全新的浮层 UI

# 4.3.0

依赖升级

# 4.2.2

依赖升级

# 4.2.1

依赖升级

# 4.1.0

依赖升级

# 4.0.0


最低版本设置为3.22.0
依赖升级


# 3.0.2

升级vm_service到13.0

# 3.0.1

修复标题高度溢出的问题


# 3.0.0

* 升级适配全部依赖到最新版

## [1.1.1+1]

* Update latest dependencies.

## [1.1.1]

* #66 [fix] toolbar initial position is incorrect

## [1.1.0+3]

* Fix static analyze issues.

## [1.1.0+2]

* Fix static analyze issues.

## [1.1.0]

* #76 Introduce `UMEWidget.closeActivatedPlugin()`. Issue #35
* #75 Remove overlay entry only when it's been inserted. Issue #65
* #72 [Android] Migrate the example to the v2 embedding

## [1.0.2+1]

* Dart format.

## [1.0.2]

* Fix error in code static analysis.

## [1.0.1]

* Fix error in pubspec.yaml in example

## [1.0.0]

* Normal version with adaption of Flutter 3.
* Feature: Anywhere door (Route)

## [1.0.0-dev.0]

* Adapt Flutter 3.

## [0.3.0+1]

* Fix the version error

## [0.3.0]

* Remove static function. Use the `UMEWidget`.
* Allow insert `Widget` into Widget tree, in order to access new plugin easily.
* Fix the issue of multiple instances of FloatingWidget caused by the refresh state.
* Fix the isseue that the plugin is not displayed due to the first layout exception in AOT mode

## [0.3.0]

* 移除静态方法，更换为壳 Widget
* 允许在 Widget tree 增加自定义嵌套结构组件，从而快速接入新插件
* 修复刷新状态引发的浮窗组件出现多实例的问题
* 修复在 AOT 模式下首次布局异常导致插件不展示的问题

## [0.2.1]

* Remove the extra MaterialApp Widget

## [0.2.0-dev.0]

* Adapted Null-Safety.

## [0.1.0+1]

* Add some docs comments, modify description in pubspec.yaml.

## [0.1.0]

* Open source.
