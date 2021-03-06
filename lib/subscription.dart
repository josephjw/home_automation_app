import 'package:flutter/material.dart';
import 'package:home_automation/colors.dart';
import 'package:home_automation/models/user_data.dart';
import 'package:home_automation/utils/show_progress.dart';
import 'package:home_automation/utils/internet_access.dart';
import 'package:home_automation/utils/show_dialog.dart';
import 'package:home_automation/utils/show_internet_status.dart';
import 'package:home_automation/utils/check_platform.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:home_automation/models/subscription_data.dart';

class SubscriptionScreen extends StatefulWidget {
  final User user;
  SubscriptionScreen({this.user});
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState(user);
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    implements SubscriptionContract {
  bool _isLoading = true;
  bool internetAccess = false;
  CheckPlatform _checkPlatform;

  User user;
  ShowDialog showDialog;
  ShowInternetStatus _showInternetStatus;

  var scaffoldKey = new GlobalKey<ScaffoldState>();
  var subscriptionRefreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();

  List<Subscription> subscriptionList = new List();
  SubscriptionPresenter _subscriptionPresenter;

  _SubscriptionScreenState(User user) {
    this.user = user;
  }

  @override
  initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _checkPlatform = new CheckPlatform(context: context);
    _showInternetStatus = new ShowInternetStatus();
    _subscriptionPresenter = new SubscriptionPresenter(this);
    getSubscriptionList();
    showDialog = new ShowDialog();
    super.initState();
  }

  Future getInternetAccessObject() async {
    CheckInternetAccess checkInternetAccess = new CheckInternetAccess();
    bool internetAccessDummy = await checkInternetAccess.check();
    setState(() {
      internetAccess = internetAccessDummy;
    });
  }

  Future getSubscriptionList() async {
    await getInternetAccessObject();
    if (internetAccess) {
      subscriptionList =
          await _subscriptionPresenter.api.getSubscription(this.user);
    }
    setState(() => _isLoading = false);
  }

  @override
  void onError(String errorString) {
    setState(() {
      _isLoading = false;
    });
    this.showDialog.showDialogCustom(context, "Error", errorString);
  }

  TextStyle _captionStyle = TextStyle(
    color: Colors.grey,
    fontSize: 11.0,
  );
  TextStyle _valueStyle = TextStyle(
    fontSize: 18.0,
  );
  @override
  Widget build(BuildContext context) {
    Widget drawBox(Subscription subscription) {
      return Card(
        elevation: 5.0,
        child: Container(
          padding: EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            border: Border.all(color: kHAutoBlue300, width: 2.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "${subscription.hwSeries}",
                        style: _valueStyle,
                      ),
                      Text(
                        "Hardware Series",
                        style: _captionStyle,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "${subscription.leftTime}",
                        style: _valueStyle,
                      ),
                      Text(
                        "Expiration Date",
                        style: _captionStyle,
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                children: <Widget>[
                  subscription.state == "Running"
                      ? Text(
                          "${subscription.state}",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        )
                      : Text(
                          "${subscription.state}",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                  Text(
                    "State",
                    style: _captionStyle,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    Widget _getSubscriptionObject(
        List<Subscription> subscriptionList, int index, int len) {
      return Container(
        padding: EdgeInsets.all(10.0),
        child: drawBox(subscriptionList[index]),
      );
    }

    Widget createListViewIOS(
        BuildContext context, List<Subscription> subscriptionList) {
      var len = 0;
      if (subscriptionList != null) {
        len = subscriptionList.length;
      }
      return new SliverList(
        delegate: new SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            if (len == 0) {
              return Container(
                padding: EdgeInsets.only(top: 10.0),
                child: Text(
                  "You have not started using any hardwares.",
                  textAlign: TextAlign.center,
                ),
              );
            }
            if (index == 0) {
              return Container(
                padding: EdgeInsets.only(top: 10.0),
              );
            }
            return _getSubscriptionObject(subscriptionList, index - 1, len);
          },
          childCount: len + 1,
        ),
      );
    }

    Widget createListView(BuildContext context, List<Subscription> memberList) {
      var len = 0;
      if (memberList != null) {
        len = memberList.length;
      }
      return new ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          if (len == 0) {
            return Container(
              padding: EdgeInsets.only(top: 10.0),
              child: Text(
                "You have not started using any hardwares.",
                textAlign: TextAlign.center,
              ),
            );
          }
          if (index == 0) {
            return Container(
              padding: EdgeInsets.only(top: 10.0),
            );
          }
          return _getSubscriptionObject(memberList, index - 1, len);
        },
        itemCount: len + 1,
      );
    }

    return Scaffold(
      key: scaffoldKey,
      appBar: _checkPlatform.isIOS()
          ? CupertinoNavigationBar(
              backgroundColor: kHAutoBlue100,
              middle: new Text("Subscription"),
            )
          : AppBar(
              title: Text("Subscription"),
            ),
      body: _isLoading
          ? ShowProgress()
          : internetAccess
              ? _checkPlatform.isIOS()
                  ? new CustomScrollView(
                      slivers: <Widget>[
                        new CupertinoSliverRefreshControl(
                            onRefresh: getSubscriptionList),
                        new SliverSafeArea(
                          top: false,
                          sliver: createListViewIOS(context, subscriptionList),
                        ),
                      ],
                    )
                  : RefreshIndicator(
                      key: subscriptionRefreshIndicatorKey,
                      child: createListView(context, subscriptionList),
                      onRefresh: getSubscriptionList,
                    )
              : _checkPlatform.isIOS()
                  ? new CustomScrollView(
                      slivers: <Widget>[
                        new CupertinoSliverRefreshControl(
                            onRefresh: getSubscriptionList),
                        new SliverSafeArea(
                            top: false,
                            sliver: _showInternetStatus
                                .showInternetStatus(_checkPlatform.isIOS())),
                      ],
                    )
                  : RefreshIndicator(
                      key: subscriptionRefreshIndicatorKey,
                      child: _showInternetStatus
                          .showInternetStatus(_checkPlatform.isIOS()),
                      onRefresh: getSubscriptionList,
                    ),
    );
  }
}
