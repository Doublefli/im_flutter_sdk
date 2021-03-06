import 'dart:async';
import 'package:flutter/material.dart';

import 'package:im_flutter_sdk/im_flutter_sdk.dart';
import 'package:im_flutter_sdk_example/common/common.dart';
import 'package:im_flutter_sdk_example/pages/group_announcement_page.dart';
import 'package:im_flutter_sdk_example/pages/group_management_page.dart';
import 'package:im_flutter_sdk_example/pages/group_members_page.dart';
import 'package:im_flutter_sdk_example/pages/group_pick_contacts_page.dart';

import 'package:im_flutter_sdk_example/utils/localizations.dart';
import 'package:im_flutter_sdk_example/utils/style.dart';
import 'package:im_flutter_sdk_example/utils/theme_util.dart';
import 'package:im_flutter_sdk_example/utils/widget_util.dart';
import 'package:im_flutter_sdk_example/widgets/progress_dialog.dart';

import 'group_files_page.dart';

class EMGroupDetailsPage extends StatefulWidget {
  final String _groupId;

  const EMGroupDetailsPage(this._groupId);

  @override
  State<StatefulWidget> createState() {
    return _EMGroupDetailsPageState(this._groupId);
  }
}

class _EMGroupDetailsPageState extends State<EMGroupDetailsPage> {
  String _groupId;
  String _groupName = 'groupName';
  var _groupMembers = List();
  var _admins = List();
  var _blackList = List();
  var _muteList = List();
  String _owner;
  String _cursor;
  bool _isOwner = false;
  bool _isAdmin = false;
  String _currentUser;
  int _membersCount = 0;
  bool _loading = true;
  String _loadText;
  EMGroup _emGroup;

  TextEditingController _groupNameController = new TextEditingController();

  _EMGroupDetailsPageState(this._groupId);

  @override
  void initState() {
    super.initState();
    _fetchGroupDetails();
  }

  void _fetchGroupDetails() async {
    _loading = true;
    _groupMembers.clear();
    _admins.clear();
    _blackList.clear();
    _muteList.clear();

    try{
      _currentUser = EMClient.getInstance.currentUsername ?? '';
      _emGroup = await EMClient.getInstance.groupManager.getGroupSpecificationFromServer(groupId: _groupId);
      _owner = _emGroup.owner;
      _groupName = _emGroup.name;
      _membersCount = _emGroup.settings.maxCount;
      _admins = _emGroup.adminList;
      _isOwner = _owner == _currentUser;
      _isAdmin = _admins.contains(_currentUser);

      EMCursorResult result = await EMClient.getInstance.groupManager.getGroupMemberListFromServer(groupId:_groupId, cursor:_cursor);
      _groupMembers = result.data;
      _cursor = result.cursor;

      if(_isAdmin || _isOwner) {
        _blackList = await EMClient.getInstance.groupManager.getGroupBlacklistFromServer(groupId: _groupId, pageSize: 200, pageNum: 0);
        _muteList = await EMClient.getInstance.groupManager.getGroupMuteListFromServer(groupId: _groupId, pageSize: 200, pageNum: 0);
      }
    }catch(e){
      WidgetUtil.hintBoxWithDefault(e.toString());
    }finally {
      _refreshUI(false);
    }

  }

  _refreshUI(bool loading) {
    setState(() {
      _loading = loading;
    });
  }

  Widget _buildPortrait() {
    return InkWell(
      child: Container(
        margin: EdgeInsets.only(left: 20.0, right: 20.0),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    width: 0.5,
                    color: ThemeUtils.isDark(context)
                        ? EMColor.darkBorderLine
                        : EMColor.borderLine))),
        height: EMLayout.emContactListItemHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(DemoLocalizations.of(context).groupHead),
            Expanded(
              child: Text(''),
            ),
            Container(
              alignment: Alignment.centerRight,
              child: Row(
                children: <Widget>[
                  ClipOval(
                    child: Container(
                      height: EMLayout.emConListPortraitSize,
                      width: EMLayout.emConListPortraitSize,
                      child: Image.asset('images/default_avatar.png'),
                    ),
                  ),
                  SizedBox(
                    width: 10.0,
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 15.0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        WidgetUtil.hintBoxWithDefault('暂未实现');
      },
    );
  }

  Widget _buildItem() {
    return Container(
      height: EMLayout.emConListPortraitSize,
      width: EMLayout.emConListPortraitSize,
      child: Image.asset('images/default_avatar.png'),
    );
  }

  Widget _buildMembers() {
    /// 判断显示item数量
    int _count = _membersCount;
    if (_membersCount > 7) {
      _count = 7;
    }
      if (_isOwner || _isAdmin) {
        if (_membersCount > 4) {
          _count = 7;
        } else {
          _count = _membersCount + 2;
        }
      }else if(!_emGroup.settings.inviteNeedConfirm){
        if (_membersCount > 5) {
          _count = 7;
        }else {
          _count = _membersCount + 1;
        }
    }

    return InkWell(
//        highlightColor: Colors.transparent,
//         radius: 0.0,
        onTap: () {
          Navigator.push<bool>(context,
              new MaterialPageRoute(builder: (BuildContext context) {
            return EMGroupMembersPage(this._groupId, this._groupMembers,
                this._cursor, this._currentUser, this._blackList, this._muteList, this._admins, this._owner, Constant.defaultGroupMember);
          })).then((bool _isRefresh){_isRefreshUI(_isRefresh);});
        },
        child: Container(
          margin: EdgeInsets.only(left: 20.0, right: 20.0),
          padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: <Widget>[
                    Text(DemoLocalizations.of(context).groupMembers),
                    Expanded(
                      child: Text(''),
                    ),
                    Container(
                      alignment: Alignment.centerRight,
                      child: Row(
                        children: <Widget>[
                          Text(_membersCount.toString() + '人'),
                          SizedBox(
                            width: 10.0,
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 15.0,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                child: GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _count,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.75),
                    itemBuilder: (BuildContext context, int index) {
                      if (((_isOwner || _isAdmin) && _count - index == 2)
                          || (!(_isOwner || _isAdmin)  && _count - index == 1 && !_emGroup.settings.inviteNeedConfirm)) {
                        return IconButton(
                          icon: Image.asset('images/add_member.png'),
                          onPressed: () async {
                            Navigator.push<List<String>>(context, MaterialPageRoute(builder: (BuildContext context){return EMGroupPickContactsPage(this._groupId);
                            })).then((List<String> contacts){
                              if(contacts.length > 0){
                                try{
                                  EMClient.getInstance.groupManager.addMembers(groupId:_groupId, members: contacts);
                                  WidgetUtil.hintBoxWithDefault('群组邀请发送成功');
                                  _refreshUI(false);
                                }catch (e){
                                  WidgetUtil.hintBoxWithDefault(e.toString());
                                  _refreshUI(false);
                                }
                              }
                            });
                          },
                        );
                      }
                      if ((_isOwner || _isAdmin) && _count - index == 1) {
                        return IconButton(
                          icon: Image.asset('images/remove_member.png'),
                          onPressed: () {
                            Navigator.push<bool>(context,
                                new MaterialPageRoute(
                                    builder: (BuildContext context) {
                              return EMGroupMembersPage(
                                  this._groupId,
                                  this._groupMembers,
                                  this._cursor,
                                  this._currentUser,
                                  this._blackList, this._muteList, this._admins, this._owner,
                                  Constant.removeGroupMember);
                            })).then((bool _isRefresh){_isRefreshUI(_isRefresh);});
                          },
                        );
                      }
                      return _buildItem();
                    }),
              ),
            ],
          ),
        ));
  }

  Widget _buildBlankWidget() {
    return Container(
      height: 25.0,
      color: ThemeUtils.isDark(context)
          ? EMColor.darkUnselectedItemColor
          : EMColor.unselectedItemColor,
    );
  }

  Widget _buildGroupName() {

    return InkWell(
      child: Container(
        margin: EdgeInsets.only(left: 20.0, right: 20.0),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    width: 0.5,
                    color: ThemeUtils.isDark(context)
                        ? EMColor.darkBorderLine
                        : EMColor.borderLine))),
        height: EMLayout.emContactListItemHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(DemoLocalizations.of(context).groupName),
            Expanded(
              child: Text(''),
            ),
            Container(
              alignment: Alignment.centerRight,
              child: Row(
                children: <Widget>[
                  Text(_groupName),
                  SizedBox(
                    width: 10.0,
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 15.0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        if (_isOwner) {
          showDialog(
              context: context,
              barrierDismissible: true,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Center(
                    child: Text(
                      DemoLocalizations.of(context).changeGroupName,
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  content: Container(
                    height: EMLayout.emSearchBarHeight,
                    child: TextField(
                      autofocus: true,
                      controller: _groupNameController,
                      decoration: InputDecoration(),
                    ),
                  ),
                  actions: <Widget>[
                    FlatButton(
                      child: Text(DemoLocalizations.of(context).no),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    FlatButton(
                      child: Text(DemoLocalizations.of(context).yes),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        _refreshUI(true);
                        try{
                          EMClient.getInstance.groupManager.changeGroupName(groupId:_groupId, name:_groupNameController.text);
                          WidgetUtil.hintBoxWithDefault('修改群名称成功');
                          _fetchGroupDetails();
                        }catch(e){
                          WidgetUtil.hintBoxWithDefault(e.toString());
                          _fetchGroupDetails();
                        }
                      },
                    ),
                  ],
                );
              });
        } else {
          WidgetUtil.hintBoxWithDefault('无操作权限');
        }
      },
    );
  }

  Widget _buildGroupFile() {
    return InkWell(
      child: Container(
        margin: EdgeInsets.only(left: 20.0, right: 20.0),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    width: 0.5,
                    color: ThemeUtils.isDark(context)
                        ? EMColor.darkBorderLine
                        : EMColor.borderLine))),
        height: EMLayout.emContactListItemHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('群文件'),
            Expanded(
              child: Text(''),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 15.0,
            ),
          ],
        ),
      ),
      onTap: () {
        Navigator.push(context,
            new MaterialPageRoute(builder: (BuildContext context) {
          return EMGroupFilesPage(this._groupId);
        }));
      },
    );
  }

  Widget _buildAnnouncement() {
    return InkWell(
      child: Container(
        margin: EdgeInsets.only(left: 20.0, right: 20.0),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    width: 0.5,
                    color: ThemeUtils.isDark(context)
                        ? EMColor.darkBorderLine
                        : EMColor.borderLine))),
        height: EMLayout.emContactListItemHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(DemoLocalizations.of(context).groupAnnouncement),
            Expanded(
              child: Text(''),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 15.0,
            ),
          ],
        ),
      ),
      onTap: () {
        Navigator.push<String>(context,
            new MaterialPageRoute(builder: (BuildContext context) {
          return EMGroupAnnouncementPage(this._groupId, _isOwner || _isAdmin);
        })).then((String announcement) {
          if(_isOwner || _isAdmin){
            _loading = true;
            try{
              EMClient.getInstance.groupManager.updateGroupAnnouncement(groupId: _groupId, announcement: announcement);
              WidgetUtil.hintBoxWithDefault('群公告更新成功');
              _refreshUI(false);
            }catch(e){
              WidgetUtil.hintBoxWithDefault(e.toString());
              _refreshUI(false);
            }
          }
        });
      },
    );
  }

  Widget _buildGroupManagement() {
    return Visibility(
      visible: _isOwner || _isAdmin,
      child: InkWell(
        child: Container(
          margin: EdgeInsets.only(left: 20.0, right: 20.0),
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      width: 0.5,
                      color: ThemeUtils.isDark(context)
                          ? EMColor.darkBorderLine
                          : EMColor.borderLine))),
          height: EMLayout.emContactListItemHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(DemoLocalizations.of(context).groupManagement),
              Expanded(
                child: Text(''),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 15.0,
              ),
            ],
          ),
        ),
        onTap: () {
          if (_isOwner || _isAdmin) {
            Navigator.push<bool>(context,
                new MaterialPageRoute(builder: (BuildContext context) {
                  return EMGroupManagementPage(this._groupId, this._isOwner, this._blackList, this._muteList, this._admins);
                })).then((bool _isRefresh){_isRefreshUI(_isRefresh);});
          } else {
            WidgetUtil.hintBoxWithDefault('无权限操作');
          }
        },
      ),
    );
  }

  Widget _buildSearchMsg() {
    return InkWell(
      child: Container(
        margin: EdgeInsets.only(left: 20.0, right: 20.0),
        decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(
                    width: 0.5,
                    color: ThemeUtils.isDark(context)
                        ? EMColor.darkBorderLine
                        : EMColor.borderLine))),
        height: EMLayout.emContactListItemHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('查找聊天记录'),
            Expanded(
              child: Text(''),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 15.0,
            ),
          ],
        ),
      ),
      onTap: () {
        WidgetUtil.hintBoxWithDefault('功能暂未实现');
      },
    );
  }

  Widget _buildExitWidget() {
    String exit = DemoLocalizations.of(context).exitGroup;
    if (_isOwner) {
      exit = DemoLocalizations.of(context).destroyGroup;
    }
    return InkWell(
      child: Container(
        height: 50.0,
        child: Center(
          child: Text(
            exit,
            style: TextStyle(
                color:
                    ThemeUtils.isDark(context) ? EMColor.darkRed : EMColor.red),
          ),
        ),
      ),
      onTap: () async {
        try{
          if(_isOwner) {
            EMClient.getInstance.groupManager.destroyGroup(groupId: _groupId);
            WidgetUtil.hintBoxWithDefault('解散群组成功');
            Navigator.of(context).pop(true);
          } else {
            EMClient.getInstance.groupManager.leaveGroup(groupId: _groupId);
            WidgetUtil.hintBoxWithDefault('退出群组成功');
            Navigator.of(context).pop(true);
          }
        }catch(e){
          WidgetUtil.hintBoxWithDefault(e.toString());
        }
      },
    );
  }

  Widget _buildListView(){
    return ListView.builder(
        scrollDirection: Axis.vertical,
        itemCount: _emGroup == null ? 0 : 11,
        itemBuilder: (BuildContext context, int index){
          switch(index){
            case 0:
              return _buildPortrait();
            case 1:
              return _buildMembers();
            case 2:
              return _buildBlankWidget();
            case 3:
              return _buildGroupName();
            case 4:
              return _buildGroupFile();
            case 5:
              return _buildAnnouncement();
            case 6:
              return _buildGroupManagement();
            case 7:
              return _buildBlankWidget();
            case 8:
              return _buildSearchMsg();
            case 9:
              return _buildBlankWidget();
            case 10:
              return _buildExitWidget();
            default:
              return _buildBlankWidget();
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    _loadText = DemoLocalizations.of(context).loading;
    return WillPopScope(
      onWillPop: _willPop,
      child: Scaffold(
          appBar: WidgetUtil.buildAppBar(
              context, DemoLocalizations.of(context).groupDetails),
          key: UniqueKey(),
          body: Stack(
            children: <Widget>[
              _buildListView(),
              ProgressDialog(
                loading: _loading,
                msg: _loadText,
              ),
            ],
          )
      ),
    );
  }

  Future<bool> _willPop () { //返回值必须是Future<bool>
    Navigator.of(context).pop(false);
    return Future.value(false);
  }

  void _isRefreshUI(bool _isRefresh){
    if(_isRefresh){
      _fetchGroupDetails();
    }
  }
}
