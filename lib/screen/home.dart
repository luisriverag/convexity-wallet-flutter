import 'package:convex_wallet/convex.dart';
import 'package:convex_wallet/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../route.dart' as route;
import '../nav.dart' as nav;
import '../widget.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Convexity'),
        actions: [
          if (appState.model.allKeyPairs.isNotEmpty)
            IdenticonDropdown(
              activeKeyPair: appState.model.activeKeyPairOrDefault(),
              allKeyPairs: appState.model.allKeyPairs,
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Text('Convexity'),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              title: Text('Wallet'),
              onTap: () {
                Navigator.pop(context);

                Navigator.pushNamed(context, route.wallet);
              },
            ),
          ],
        ),
      ),
      body: HomeScreenBody(),
    );
  }
}

class HomeScreenBody extends StatelessWidget {
  Widget action(
    BuildContext context,
    String label,
    void Function() onPressed,
  ) =>
      Column(
        children: [
          Container(
            decoration: const ShapeDecoration(
              color: Colors.lightBlue,
              shape: CircleBorder(),
            ),
            child: IconButton(
              icon: Icon(Icons.money),
              color: Colors.white,
              onPressed: onPressed,
            ),
          ),
          Gap(6),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
            ),
          )
        ],
      );

  void showTodoSnackBar(BuildContext context) =>
      Scaffold.of(context).showSnackBar(SnackBar(content: Text('TODO')));

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final activeKeyPair = appState.model.activeKeyPairOrDefault();

    final actions = [
      action(
        context,
        'Address Book',
        () => nav.pushAddressBook(context),
      ),
      action(
        context,
        'My Tokens',
        () => nav.pushMyTokens(context),
      ),
      action(
        context,
        'Assets',
        () => nav.pushAssets(context),
      ),
      action(
        context,
        'Transfer',
        () => nav.pushTransfer(context),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activeKeyPair != null)
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Identicon(keyPair: activeKeyPair),
                    title: Text(
                      appState.model.activeAddress.toString(),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      'Address',
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                            text: appState.model.activeAddress.toString(),
                          ),
                        );

                        Scaffold.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Copied ${appState.model.activeAddress.toString()}',
                              overflow: TextOverflow.clip,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  FutureBuilder<Account>(
                    future: appState
                        .convexClient()
                        .account(address: appState.model.activeAddress),
                    builder: (context, snapshot) {
                      var animatedChild;

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        animatedChild = SizedBox(
                          height: 63,
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'loading...',
                              style: TextStyle(color: Colors.black38),
                            ),
                          ),
                        );
                      } else {
                        animatedChild = Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (snapshot.data?.balance == null
                                        ? '-'
                                        : NumberFormat()
                                            .format(snapshot.data.balance)),
                                    textAlign: TextAlign.start,
                                  ),
                                  Text(
                                    'Balance',
                                    style: Theme.of(context).textTheme.caption,
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (snapshot.data?.memorySize?.toString() ??
                                        '-'),
                                    textAlign: TextAlign.start,
                                  ),
                                  Text(
                                    'Memory Size',
                                    style: Theme.of(context).textTheme.caption,
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(snapshot.data?.sequence?.toString() ??
                                      '-'),
                                  Text(
                                    'Sequence',
                                    style: Theme.of(context).textTheme.caption,
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      }

                      return AnimatedSwitcher(
                        duration: Duration(milliseconds: 500),
                        child: animatedChild,
                      );
                    },
                  ),
                ],
              ),
            ),
          Gap(20),
          Expanded(
            child: AnimationLimiter(
              child: GridView.count(
                primary: false,
                padding: const EdgeInsets.all(20),
                crossAxisSpacing: 10,
                mainAxisSpacing: 24,
                crossAxisCount: 4,
                children: actions
                    .asMap()
                    .entries
                    .map(
                      (e) => AnimationConfiguration.staggeredGrid(
                        position: e.key,
                        columnCount: 4,
                        child: ScaleAnimation(
                          child: FadeInAnimation(child: e.value),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
