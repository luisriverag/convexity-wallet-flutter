import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:barcode_scan/barcode_scan.dart';

import '../model.dart';
import '../nav.dart';
import '../widget.dart';
import '../convex.dart' as convex;

class TransferScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transfer')),
      body: TransferScreenBody(),
    );
  }
}

class TransferScreenBody extends StatefulWidget {
  @override
  _TransferScreenBodyState createState() => _TransferScreenBodyState();
}

class _TransferScreenBodyState extends State<TransferScreenBody> {
  var isTransfering = false;

  var formKey = GlobalKey<FormState>();

  var targetController = TextEditingController();
  var amountController = TextEditingController();

  void scan() async {
    var result = await BarcodeScanner.scan();

    setState(() {
      targetController.text = result.rawContent;
    });
  }

  void transfer({
    BuildContext context,
    convex.Address to,
    int amount,
  }) async {
    setState(() {
      isTransfering = true;
    });

    final appState = context.read<AppState>();

    final result = await appState.convexClient().transact(
          caller: appState.model.activeAddress,
          callerSecretKey: appState.model.activeKeyPair.sk,
          source: '(transfer 0x${to.hex} $amount)',
        );

    Scaffold.of(context).showSnackBar(
      SnackBar(
        content: Text('${result.value}'),
      ),
    );

    setState(() {
      isTransfering = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            Row(
              children: [
                IdenticonDropdown(
                  activeKeyPair: appState.model.activeKeyPair,
                  allKeyPairs: appState.model.allKeyPairs,
                ),
                Expanded(
                  child: Text(
                    appState.model.activeAddress?.toString(),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              ],
            ),
            TextFormField(
              readOnly: true,
              autofocus: false,
              controller: targetController,
              decoration: InputDecoration(
                labelText: 'Destination',
                hintText: 'Address of payee',
              ),
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter the address.';
                }

                return null;
              },
              onTap: () {
                pushSelectAccount(context).then((selectedAddress) {
                  if (selectedAddress != null) {
                    setState(() {
                      targetController.text = selectedAddress.toString();
                    });
                  }
                });
              },
            ),
            TextFormField(
              keyboardType: TextInputType.number,
              controller: amountController,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Amount',
                hintText: 'Amount in Convex Coins',
              ),
              validator: (value) {
                if (value.isEmpty) {
                  return 'Please enter the amount.';
                }

                if (int.tryParse(value) == null) {
                  return 'Please enter the amount as number.';
                }

                return null;
              },
            ),
            ElevatedButton(
              child: isTransfering
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(),
                    )
                  : Text('Transfer'),
              onPressed: isTransfering
                  ? null
                  : () {
                      if (formKey.currentState.validate()) {
                        transfer(
                          context: context,
                          to: convex.Address.fromHex(targetController.text),
                          amount: int.parse(amountController.text),
                        );
                      }
                    },
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    targetController.dispose();
    amountController.dispose();

    super.dispose();
  }
}
