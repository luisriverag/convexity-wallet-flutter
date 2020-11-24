import 'package:barcode_scan/barcode_scan.dart';
import 'package:convex_wallet/convex.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';

import '../widget.dart';
import '../model.dart';

enum _Option {
  recommended,
  scanQRCode,
  search,
  myHoldings,
  assetId,
}

class FollowAssetScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Follow Asset')),
      body: FollowAssetScreenBody(),
    );
  }
}

class FollowAssetScreenBody extends StatefulWidget {
  @override
  _FollowAssetScreenBodyState createState() => _FollowAssetScreenBodyState();
}

class _FollowAssetScreenBodyState extends State<FollowAssetScreenBody> {
  var selectedOption = _Option.scanQRCode;

  Widget option({
    @required String title,
    @required _Option value,
  }) =>
      RadioListTile(
        title: Text(title),
        value: value,
        groupValue: selectedOption,
        onChanged: (value) {
          setState(() {
            selectedOption = value;
          });
        },
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          option(
            title: 'Scan QR Code',
            value: _Option.scanQRCode,
          ),
          option(
            title: 'Recommended',
            value: _Option.recommended,
          ),
          option(
            title: 'Asset Address',
            value: _Option.assetId,
          ),
          Gap(20),
          Expanded(
            child: OptionRenderer(
              option: selectedOption,
            ),
          )
        ],
      ),
    );
  }
}

class OptionRenderer extends StatelessWidget {
  final _Option option;

  const OptionRenderer({Key key, this.option}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (option) {
      case _Option.recommended:
        return _Recommended();
      case _Option.scanQRCode:
        return _ScanQRCode();
      case _Option.search:
        return _Search();
      case _Option.myHoldings:
        return _MyHoldings();
      case _Option.assetId:
        return _AssetID();
    }

    throw Exception("No renderer for $option");
  }
}

class _Recommended extends StatefulWidget {
  @override
  _RecommendedState createState() => _RecommendedState();
}

class _RecommendedState extends State<_Recommended> {
  var isLoading = true;
  var assets = <AssetMetadata>[];

  void initState() {
    super.initState();

    context.read<AppState>().convexity().allAssets().then((assets) {
      // It's important to check if the Widget is mounted
      // because the user might change the selected option
      // while we're still loading the recommended Assets.
      if (mounted) {
        setState(
          () {
            this.isLoading = false;
            this.assets = assets;
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var following = context.watch<AppState>().model.following;

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        children: assets
            .map(
              (token) => Stack(
                children: [
                  TokenRenderer(
                    token: token,
                    onTap: (metadata) {
                      var followingCopy = Set<AssetMetadata>.from(following);

                      if (followingCopy.contains(metadata)) {
                        followingCopy.remove(metadata);
                      } else {
                        followingCopy.add(metadata);
                      }

                      context.read<AppState>().setFollowing(
                            followingCopy,
                            isPersistent: true,
                          );
                    },
                  ),
                  if (following.contains(token))
                    Container(
                      padding: const EdgeInsets.all(8),
                      alignment: Alignment.topRight,
                      child: Icon(
                        Icons.check,
                        color: Colors.green,
                      ),
                    )
                ],
              ),
            )
            .toList(),
      );
    }
  }
}

enum _ScanQRCodeStatus {
  ready,
  loading,
  loaded,
}

class _ScanQRCode extends StatefulWidget {
  @override
  _ScanQRCodeState createState() => _ScanQRCodeState();
}

class _ScanQRCodeState extends State<_ScanQRCode> {
  _ScanQRCodeStatus status = _ScanQRCodeStatus.ready;

  Address scannedAddress;
  AssetMetadata token;

  void scan() async {
    var r = await BarcodeScanner.scan();
    var rawContent = r.rawContent ?? "";

    if (rawContent.isNotEmpty) {
      var scannedAddress = Address(hex: rawContent);

      setState(() {
        this.scannedAddress = scannedAddress;
        this.status = _ScanQRCodeStatus.loading;
      });

      var convexity = context.read<AppState>().convexity();

      print('Asset Metadata $scannedAddress');

      var token = await convexity.assetMetadata(scannedAddress);

      setState(() {
        status = _ScanQRCodeStatus.loaded;
      });

      print('Token $token');
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case _ScanQRCodeStatus.ready:
        return Column(
          children: [
            QrImage(
              data: 'Convexity',
              version: QrVersions.auto,
              size: 160,
            ),
            ElevatedButton(
              child: Text('Scan QR Code'),
              onPressed: () {
                scan();
              },
            ),
          ],
        );
      case _ScanQRCodeStatus.loading:
        return Column(
          children: [
            Text(scannedAddress.hex),
            CircularProgressIndicator(),
          ],
        );
      case _ScanQRCodeStatus.loaded:
        return Column(
          children: [
            Text(scannedAddress.hex),
          ],
        );
      default:
        return Text('-');
    }
  }
}

class _Search extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Search'),
    );
  }
}

class _MyHoldings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('My Holdings'),
    );
  }
}

class _AssetID extends StatefulWidget {
  @override
  _AssetIDState createState() => _AssetIDState();
}

class _AssetIDState extends State<_AssetID> {
  var status = AssetMetadataQueryStatus.ready;

  String address;
  AssetMetadata assetMetadata;

  Widget body() {
    switch (status) {
      case AssetMetadataQueryStatus.ready:
        return Center(child: Text(''));

      case AssetMetadataQueryStatus.inProgress:
        return Center(child: CircularProgressIndicator());

      case AssetMetadataQueryStatus.done:
        return Column(
          children: [
            SizedBox(
              width: 160,
              child: TokenRenderer(token: assetMetadata),
            ),
            ElevatedButton(
              child: Text('Follow'),
              onPressed: () {
                context
                    .read<AppState>()
                    .followAsset(assetMetadata, isPersistent: true);

                Navigator.pop(context);
              },
            )
          ],
        );

      case AssetMetadataQueryStatus.missingMetadata:
        return Center(
          child: Text(
            'This Address is not registered with Convexity.',
            style: TextStyle(color: Colors.orange),
          ),
        );

      case AssetMetadataQueryStatus.notFound:
        return Center(
          child: Text('Sorry. The Asset was not found.'),
        );

      default:
        return Center(child: Text(''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Address',
          ),
          onChanged: (value) {
            setState(() {
              address = Address.trim0x(value);
              status = AssetMetadataQueryStatus.ready;
            });
          },
        ),
        TextButton(
          child: Text('Verify'),
          onPressed: (AssetMetadataQueryStatus.inProgress == status)
              ? null
              : () {
                  setState(() {
                    status = AssetMetadataQueryStatus.inProgress;
                  });

                  context
                      .read<AppState>()
                      .convexity()
                      .assetMetadata(Address(hex: address))
                      .then(
                    (_assetMetadata) {
                      // It's important to check wether the Widget is mounted,
                      // because the user might change the selected option
                      // while there is still a query a progress.
                      if (mounted) {
                        setState(() {
                          status = _assetMetadata == null
                              ? AssetMetadataQueryStatus.missingMetadata
                              : AssetMetadataQueryStatus.done;

                          assetMetadata = _assetMetadata;
                        });
                      }
                    },
                  );
                },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 22),
          child: body(),
        ),
      ],
    );
  }
}

enum AssetMetadataQueryStatus {
  /// Initial status.
  ready,

  /// Query is in progress.
  inProgress,

  /// The Asset exists on the Convex Network, but there is not metadata available.
  missingMetadata,

  /// The Asset doesn't exist on the Convex Network.
  notFound,

  /// The Asset exists on the Convex Network, and there is metadata available.
  done,
}