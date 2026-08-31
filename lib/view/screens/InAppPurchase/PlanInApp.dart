// import 'dart:io';
// import 'package:biblebookapp/view/constants/theme_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:in_app_purchase/in_app_purchase.dart';
// import 'package:in_app_purchase_android/billing_client_wrappers.dart';
// import 'package:in_app_purchase_android/in_app_purchase_android.dart';
// import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

// import 'package:provider/provider.dart';


// class PaymentScreen extends StatefulWidget {
//   @override
//   _PaymentScreenState createState() => _PaymentScreenState();
// }

// class _PaymentScreenState extends State<PaymentScreen> {
//   late ThemeProvider _appProvider;

//   @override
//   void initState() {
//     final provider = Provider.of<ThemeProvider>(context, listen: false);
//     _appProvider = provider;
//     inAppStream(provider);
//     super.initState();
//   }
//   inAppStream(provider) async {
//     await provider.inAppStream();
//   }
//   @override
//   void dispose() {
//     if (Platform.isIOS) {
//       var iosPlatformAddition = _appProvider.inAppPurchase
//           .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
//       iosPlatformAddition.setDelegate(null);
//     }
//     _appProvider.subscription.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<ThemeProvider>(context);

//     List<Widget> stack = [];
//     if (provider.queryProductError == null) {
//       stack.add(
//         ListView(
//           children: [
//             _buildConnectionCheckTile(provider),
//             _buildProductList(provider),
//           ],
//         ),
//       );
//     } else {
//       stack.add(Center(
//         child: Text(provider.queryProductError!),
//       ));
//     }
//     if (provider.purchasePending) {
//       stack.add(
//         Stack(
//           children: [
//             Opacity(
//               opacity: 0.3,
//               child: const ModalBarrier(dismissible: false, color: Colors.grey),
//             ),
//             Center(
//               child: CircularProgressIndicator(),
//             ),
//           ],
//         ),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('IAP Example'),
//       ),
//       body: Stack(
//         children: stack,
//       ),
//     );
//   }

//   Card _buildConnectionCheckTile(provider) {
//     if (provider.loading) {
//       return Card(child: ListTile(title: const Text('Trying to connect...')));
//     }
//     final Widget storeHeader = provider.notFoundIds.isNotEmpty
//         ? ListTile(
//         leading: Icon(Icons.block,
//             color: provider.isAvailable
//                 ? Colors.grey
//                 : ThemeData.light().errorColor),
//         title: Text('The store is unavailable'))
//         : ListTile(
//       leading: Icon(Icons.check, color: Colors.green),
//       title: Text('The store is available'),
//     );
//     final List<Widget> children = <Widget>[storeHeader];

//     if (!provider.isAvailable) {
//       children.addAll([
//         Divider(),
//         ListTile(
//           title: Text('Not connected',
//               style: TextStyle(color: ThemeData.light().errorColor)),
//           subtitle: const Text(
//               'Unable to connect to the payments processor. Has this app been configured correctly? See the example README for instructions.'),
//         ),
//       ]);
//     }
//     return Card(child: Column(children: children));
//   }

//   Card _buildProductList(provider) {
//     if (provider.loading) {
//       return Card(
//           child: (ListTile(
//               leading: CircularProgressIndicator(),
//               title: Text('Fetching products...'))));
//     }
//     if (!provider.isAvailable) {
//       return Card();
//     }
//     final ListTile productHeader = ListTile(title: Text('Products for Sale'));
//     List<ListTile> productList = <ListTile>[];
//     if (provider.notFoundIds.isNotEmpty) {
//       productList.add(ListTile(
//         title: Text('Products not found',
//             style: TextStyle(color: ThemeData.light().errorColor)),
//       ));
//     }

//     // This loading previous purchases code is just a demo. Please do not use this as it is.
//     // In your app you should always verify the purchase data using the `verificationData` inside the [PurchaseDetails] object before trusting it.
//     // We recommend that you use your own server to verify the purchase data.
//     Map<String, PurchaseDetails> purchasesIn =
//     Map.fromEntries(purchases.map((PurchaseDetails purchase) {
//       if (purchase.pendingCompletePurchase) {
//         provider.inAppPurchase.completePurchase(purchase);
//       }
//       return MapEntry<String, PurchaseDetails>(purchase.productID, purchase);
//     }));
//     productList.addAll(products.map(
//           (ProductDetails productDetails) {
//         PurchaseDetails? previousPurchase = purchasesIn[productDetails.id];
//         return ListTile(
//             title: Text(
//               productDetails.title,
//             ),
//             subtitle: Text(
//               productDetails.description,
//             ),
//             trailing: previousPurchase != null
//                 ? IconButton(
//                 onPressed: () => provider.confirmPriceChange(context),
//                 icon: Icon(
//                   Icons.check,
//                   color: Colors.green,
//                   size: 40,
//                 ))
//                 : TextButton(
//               child: Text(productDetails.id == kConsumableId &&
//                   provider.consumables.length > 0
//                   ? "Buy more\n${productDetails.price}"
//                   : productDetails.price),
//               style: TextButton.styleFrom(
//                 backgroundColor: Colors.green[800],
//                 primary: Colors.white,
//               ),
//               onPressed: () {
//                 late PurchaseParam purchaseParam;

//                 if (Platform.isAndroid) {
//                   // NOTE: If you are making a subscription purchase/upgrade/downgrade, we recommend you to
//                   // verify the latest status of you your subscription by using server side receipt validation
//                   // and update the UI accordingly. The subscription purchase status shown
//                   // inside the app may not be accurate.
//                   final oldSubscription = provider.getOldSubscription(
//                       productDetails, purchasesIn);

//                   purchaseParam = GooglePlayPurchaseParam(
//                       productDetails: productDetails,
//                       applicationUserName: null,
//                       changeSubscriptionParam: (oldSubscription != null)
//                           ? ChangeSubscriptionParam(
//                         oldPurchaseDetails: oldSubscription,
//                         prorationMode: ProrationMode
//                             .immediateWithTimeProration,
//                       )
//                           : null);
//                 } else {
//                   purchaseParam = PurchaseParam(
//                     productDetails: productDetails,
//                     applicationUserName: null,
//                   );
//                 }

//                 if (productDetails.id == kConsumableId) {
//                   provider.inAppPurchase.buyConsumable(
//                       purchaseParam: purchaseParam,
//                       autoConsume: kAutoConsume || Platform.isIOS);
//                 } else {
//                   provider.inAppPurchase
//                       .buyNonConsumable(purchaseParam: purchaseParam);
//                 }


//               },
//             ));
//       },
//     ));

//     return Card(
//         child:
//         Column(children: <Widget>[productHeader, Divider()] + productList));
//   }
// }