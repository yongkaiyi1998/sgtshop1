import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sgtshop/user.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:sgtshop/mainpage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:toast/toast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoder/geocoder.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:random_string/random_string.dart';
import 'package:intl/intl.dart';
import 'payment.dart';

void main() => runApp(Cart());

class Cart extends StatefulWidget {
  final User user;
  const Cart({Key key, this.user}) : super(key: key);
  @override
  _CartState createState() => _CartState();
}

class _CartState extends State<Cart> {
  double screenHeight, screenWidth;
  List cartData;
  double _weight = 0.0, _totalprice = 0.0;
  String titlecenter = "Loading cart";
  bool _selfPickup = true;
  bool _homeDelivery = false;
  bool _storeCredit = false;
  double amountpayable;
  String curaddress;
  double deliverycharge;
  Position _currentPosition;
  double latitude, longitude;
  String server = "https://yhkywy.com/sgtshop";
  Completer<GoogleMapController> _controller = Completer();
  CameraPosition _userpos;
  MarkerId markerId1 = MarkerId("12");
  Set<Marker> markers = Set();
  CameraPosition _home;
  GoogleMapController gmcontroller;

  @override
  void initState() {
    super.initState();
    _getLocation();
    _loadCart();
    if (widget.user.email == "unregistered@sgtshop.com") {
      titlecenter = 'Please register to continue...';
    } else if (widget.user.email == "admin@sgtshop.com") {
      titlecenter = 'Admin mode';
    } else if (widget.user.quantity == "0") {
      titlecenter = 'Nothing here';
    }
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
          decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('assets/images/main03.jpg'),
                  fit: BoxFit.cover)),
          child: Column(
            children: <Widget>[
              

              ///content///
              cartData == null
                  ? Flexible(
                      child: Container(
                          child: Center(
                              child: Text(
                      titlecenter,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ))))
                  : Expanded(
                      child: ListView.builder(
                          itemCount: cartData == null ? 1 : cartData.length + 2,
                          itemBuilder: (context, index) {
                            if (index == cartData.length) {
                              return Container(
                                  height: screenHeight / 2.4,
                                  width: screenWidth / 2.5,
                                  child: InkWell(
                                    child: Card(
                                      color: Colors.purple[300],
                                      child: Column(
                                        children: <Widget>[
                                          SizedBox(
                                            height: 5,
                                          ),
                                          Text("Delivery Option",
                                              style: TextStyle(
                                                  fontSize: 18.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white)),
                                          Text(
                                              "Weight:" +
                                                  _weight.toString() +
                                                  " KG",
                                              style: TextStyle(
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white)),
                                          Expanded(
                                              child: Row(
                                            children: <Widget>[
                                              Container(
                                                width: screenWidth / 2,
                                                // height: screenHeight / 3,
                                                ///left side
                                                child: Column(
                                                  children: <Widget>[
                                                    Row(
                                                      children: <Widget>[
                                                        CupertinoSwitch(
                                                          activeColor:
                                                              Colors.purple,
                                                          trackColor:
                                                              Colors.white,
                                                          value: _selfPickup,
                                                          onChanged:
                                                              (bool value) {
                                                            _onSelfPickUp(
                                                                value);
                                                          },
                                                        ),
                                                        Text(
                                                          "Self Pickup",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Padding(
                                                  padding: EdgeInsets.fromLTRB(
                                                      2, 1, 2, 1),
                                                  child: SizedBox(
                                                      width: 3,
                                                      child: Container(
                                                        color: Colors.white,
                                                      ))),
                                              Expanded(
                                                  child: Container(
                                                width: screenWidth / 2,
                                                child: Column(
                                                  children: <Widget>[
                                                    Row(
                                                      children: <Widget>[
                                                        CupertinoSwitch(
                                                          activeColor:
                                                              Colors.purple,
                                                          trackColor:
                                                              Colors.white,
                                                          value: _homeDelivery,
                                                          onChanged:
                                                              (bool value) {
                                                            _onHomeDelivery(
                                                                value);
                                                          },
                                                        ),
                                                        Text(
                                                          "Home Delivery",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    FlatButton(
                                                      color: Colors.purple,
                                                      onPressed: () =>
                                                          [_loadMapDialog()],
                                                      child: Icon(
                                                        MdiIcons.earth,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    Text("Current Address:\n",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Colors.white)),
                                                    Row(
                                                      children: <Widget>[
                                                        Text("  "),
                                                        Flexible(
                                                          child: Text(
                                                            curaddress ??
                                                                "Address not set",
                                                            maxLines: 3,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              )),
                                            ],
                                          ))
                                        ],
                                      ),
                                    ),
                                  ));
                            }

                            if (index == cartData.length + 1) {
                              return Container(
                                  child: Card(
                                color: Colors.purple[300],
                                child: Column(
                                  children: <Widget>[
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Text("Payment",
                                        style: TextStyle(
                                            fontSize: 20.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                    SizedBox(height: 5),
                                    Container(
                                        padding:
                                            EdgeInsets.fromLTRB(40, 0, 40, 0),
                                        child: Table(
                                            defaultColumnWidth:
                                                FlexColumnWidth(1.0),
                                            columnWidths: {
                                              0: FlexColumnWidth(7),
                                              1: FlexColumnWidth(3),
                                            },
                                            children: [
                                              TableRow(children: [
                                                TableCell(
                                                  child: Container(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      height: 20,
                                                      child: Text(
                                                          "Total Item Price ",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .white))),
                                                ),
                                                TableCell(
                                                  child: Container(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    height: 20,
                                                    child: Text(
                                                        "RM" +
                                                                _totalprice
                                                                    .toStringAsFixed(
                                                                        2) ??
                                                            "0.0",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 14,
                                                            color:
                                                                Colors.white)),
                                                  ),
                                                ),
                                              ]),
                                              TableRow(children: [
                                                TableCell(
                                                  child: Container(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      height: 20,
                                                      child: Text(
                                                          "Delivery Charge ",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .white))),
                                                ),
                                                TableCell(
                                                  child: Container(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    height: 20,
                                                    child: Text(
                                                        "RM" +
                                                                deliverycharge
                                                                    .toStringAsFixed(
                                                                        2) ??
                                                            "0.0",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 14,
                                                            color:
                                                                Colors.white)),
                                                  ),
                                                ),
                                              ]),
                                              TableRow(children: [
                                                TableCell(
                                                  child: Container(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      height: 48,
                                                      child: Text(
                                                          "Store Credit:  RM" +
                                                              widget
                                                                  .user.credit,
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .white))),
                                                ),
                                                TableCell(
                                                  child: Container(
                                                    alignment: Alignment.centerLeft,
                                                    height: 48,
                                                    child: Column(
                                                      children: <Widget>[
                                                        Checkbox(
                                                          activeColor:
                                                              Colors.purple,
                                                          checkColor:
                                                              Colors.white,
                                                          value: _storeCredit,
                                                          onChanged:
                                                              (bool value) {
                                                            _onStoreCredit(
                                                                value);
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ]),
                                              TableRow(children: [
                                                TableCell(
                                                  child: Container(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      height: 20,
                                                      child: Text(
                                                          "Total Amount ",
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .white))),
                                                ),
                                                TableCell(
                                                  child: Container(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    height: 20,
                                                    child: Text(
                                                        "RM" +
                                                                amountpayable
                                                                    .toStringAsFixed(
                                                                        2) ??
                                                            "0.0",
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                Colors.white)),
                                                  ),
                                                ),
                                              ]),
                                            ])),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    MaterialButton(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20.0)),
                                      minWidth: 200,
                                      height: 40,
                                      child: Text('Make Payment'),
                                      color: Colors.purple,
                                      textColor: Colors.white,
                                      elevation: 10,
                                      onPressed: makePaymentDialog,
                                    ),
                                  ],
                                ),
                              ));
                            }
                            index -= 0;

                            return Card(
                                color: Colors.purple[300],
                                elevation: 10,
                                child: Padding(
                                    padding: EdgeInsets.all(5),
                                    child: Row(children: <Widget>[
                                      Column(
                                        children: <Widget>[
                                          Container(
                                            height: screenHeight / 8,
                                            width: screenWidth / 5,
                                            child: GestureDetector(
                                                child: CachedNetworkImage(
                                              fit: BoxFit.scaleDown,
                                              imageUrl: server +
                                                  "/php/productimage/${cartData[index]['pid']}.jpg",
                                              placeholder: (context, url) =>
                                                  new CircularProgressIndicator(),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      new Icon(Icons.error),
                                            )),
                                          ),
                                          Text(
                                            "RM " + cartData[index]['pprice'],
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                          padding:
                                              EdgeInsets.fromLTRB(5, 1, 10, 1),
                                          child: SizedBox(
                                              width: 2,
                                              child: Container(
                                                height: screenWidth / 3.5,
                                                color: Colors.white,
                                              ))),
                                      Container(
                                          width: screenWidth / 1.45,
                                          child: Row(
                                            children: <Widget>[
                                              Flexible(
                                                child: Column(
                                                  children: <Widget>[
                                                    Text(
                                                      cartData[index]['pname'],
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                          color: Colors.white),
                                                      maxLines: 1,
                                                    ),
                                                    Text(
                                                      "Available " +
                                                          cartData[index]
                                                              ['pquantity'] +
                                                          " unit",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    Text(
                                                      "Your Quantity " +
                                                          cartData[index]
                                                              ['cquantity'],
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    Container(
                                                        height: 20,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: <Widget>[
                                                            FlatButton(
                                                              onPressed: () => [
                                                                _updateCart(
                                                                    index,
                                                                    "add")
                                                              ],
                                                              child: Icon(
                                                                MdiIcons.plus,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                            Text(
                                                              cartData[index]
                                                                  ['cquantity'],
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                            FlatButton(
                                                              onPressed: () => [
                                                                _updateCart(
                                                                    index,
                                                                    "remove")
                                                              ],
                                                              child: Icon(
                                                                MdiIcons.minus,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ],
                                                        )),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: <Widget>[
                                                        Text(
                                                            "Total RM " +
                                                                cartData[index][
                                                                    'yourprice'],
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white)),
                                                        FlatButton(
                                                          onPressed: () => [
                                                            _deleteCart(index)
                                                          ],
                                                          child: Icon(
                                                            MdiIcons.delete,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              )
                                            ],
                                          )),
                                    ])));
                          })),
            ],
          )),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.purple,
          child: Icon(Icons.delete),
          onPressed: () {
            deleteAll();
          }),
    );
  }
///////////////////////////////////////////////////////////////////////////////////////////////////

  //////clear all cart//////
  void deleteAll() {
    showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        backgroundColor: Colors.purple[300],
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0))),
        title: new Text(
          'Remove all items from your cart?',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        actions: <Widget>[
          MaterialButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                http.post(server + "/php/deletecartrecord.php", body: {
                  "email": widget.user.email,
                }).then((res) {
                  print(res.body);

                  if (res.body == "success") {
                    _loadCart();
                  } else {
                    Toast.show("Failed", context,
                        duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
                  }
                }).catchError((err) {
                  print(err);
                });
              },
              child: Text(
                "Yes",
                style: TextStyle(
                  color: Colors.white,
                ),
              )),
          MaterialButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              )),
        ],
      ),
    );
  }

  //////self pickup status//////
  void _onSelfPickUp(bool newValue) => setState(() {
        _selfPickup = newValue;
        if (_selfPickup) {
          _homeDelivery = false;
          _updatePayment();
        } else {
          _updatePayment();
        }
      });

  ///////onhomedelivery status//////
  void _onHomeDelivery(bool newValue) {
    _getLocation();
    setState(() {
      _homeDelivery = newValue;
      if (_homeDelivery) {
        _updatePayment();
        _selfPickup = false;
      } else {
        _updatePayment();
      }
    });
  }

  void _updatePayment() {
    _weight = 0.0;
    _totalprice = 0.0;
    amountpayable = 0.0;
    setState(() {
      for (int i = 0; i < cartData.length; i++) {
        _weight = double.parse(cartData[i]['pweight']) *
                int.parse(cartData[i]['cquantity']) +
            _weight;
        _totalprice = double.parse(cartData[i]['yourprice']) + _totalprice;
      }
      _weight = _weight / 1000;
      print(_selfPickup);
      if (_selfPickup) {
        deliverycharge = 0.0;
      } else {
        if (_totalprice > 100) {
          deliverycharge = 5.00;
        } else {
          deliverycharge = _weight * 1.2;
        }
      }
      if (_homeDelivery) {
        if (_totalprice > 100) {
          deliverycharge = 5.00;
        } else {
          deliverycharge = _weight * 1.5;
        }
      }
      if (_storeCredit) {
        amountpayable =
            deliverycharge + _totalprice - double.parse(widget.user.credit);
      } else {
        amountpayable = deliverycharge + _totalprice;
      }
      print("Dev Charge:" + deliverycharge.toStringAsFixed(3));
      print(_weight);
      print(_totalprice);
    });
  }

  void makePaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        backgroundColor: Colors.purple[300],
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0))),
        title: new Text(
          'Make payment?',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        content: new Text(
          'Are you sure?',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        actions: <Widget>[
          MaterialButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                makePayment();
              },
              child: Text(
                "Ok",
                style: TextStyle(
                  color: Colors.white,
                ),
              )),
          MaterialButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.white,
                ),
              )),
        ],
      ),
    );
  }

  Future<void> makePayment() async {
    if (amountpayable < 0) {
      double newamount = amountpayable * -1;
      await _payusingstorecredit(newamount);
      _loadCart();
      return;
    }
    if (_selfPickup) {
    } else if (_homeDelivery) {
    } else {
      Toast.show("Please select delivery option", context,
          duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
    }

    var now = new DateTime.now();
    var formatter = new DateFormat('ddMMyyyy-');
    String orderid = widget.user.email.substring(1, 3) +
        "-" +
        formatter.format(now) +
        randomAlphaNumeric(6);
    print(orderid);
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => Payment(
                  user: widget.user,
                  val: _totalprice.toStringAsFixed(2),
                  orderid: orderid,
                )));
    _loadCart();
  }

  Future<void> _payusingstorecredit(double newamount) async {
    ProgressDialog pr = new ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: true);
    pr.style(message: "Updating cart");
    pr.show();
    String urlPayment = server + "/php/paymentScreen.php";
    await http.post(urlPayment, body: {
      "userid": widget.user.email,
      "amount": _totalprice.toStringAsFixed(2),
      "orderid": generateOrderid(),
      "newcr": newamount.toStringAsFixed(2)
    }).then((res) {
      print(res.body);
      pr.dismiss();
    }).catchError((err) {
      print(err);
    });
  }

  String generateOrderid() {
    var now = new DateTime.now();
    var formatter = new DateFormat('ddMMyyyy-');
    String orderid = widget.user.email.substring(1, 3) +
        "-" +
        formatter.format(now) +
        randomAlphaNumeric(6);
    return orderid;
  }

  //////load map//////
  _loadMapDialog() {
    try {
      if (_currentPosition.latitude == null) {
        Toast.show("Location not available. Please wait...", context,
            duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
        _getLocation(); //_getCurrentLocation();
        return;
      }
      _controller = Completer();
      _userpos = CameraPosition(
        target: LatLng(latitude, longitude),
        zoom: 14.4746,
      );

      markers.add(Marker(
          markerId: markerId1,
          position: LatLng(latitude, longitude),
          infoWindow: InfoWindow(
            title: 'Current Location',
            snippet: 'Delivery Location',
          )));

      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, newSetState) {
              return AlertDialog(
                backgroundColor: Colors.purple[300],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0))),
                title: Text(
                  "Select New Delivery Location",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                titlePadding: EdgeInsets.all(5),
                //content: Text(curaddress),
                actions: <Widget>[
                  Text(
                    curaddress,
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    height: screenHeight / 1.5 ?? 600,
                    width: screenWidth ?? 360,
                    child: GoogleMap(
                        mapType: MapType.normal,
                        initialCameraPosition: _userpos,
                        markers: markers.toSet(),
                        onMapCreated: (controller) {
                          _controller.complete(controller);
                        },
                        onTap: (newLatLng) {
                          _loadLoc(newLatLng, newSetState);
                        }),
                  ),
                  MaterialButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0)),
                    //minWidth: 200,
                    height: 20,
                    child: Text('Close'),
                    color: Colors.purple,
                    textColor: Colors.white,
                    elevation: 10,
                    onPressed: () =>
                        [markers.clear(), Navigator.of(context).pop(false)],
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      print(e);
      return;
    }
  }

  //////loading location//////
  void _loadLoc(LatLng loc, newSetState) async {
    newSetState(() {
      print("insetstate");
      markers.clear();
      latitude = loc.latitude;
      longitude = loc.longitude;
      _getLocationfromlatlng(latitude, longitude, newSetState);
      _home = CameraPosition(
        target: loc,
        zoom: 14,
      );
      markers.add(Marker(
          markerId: markerId1,
          position: LatLng(latitude, longitude),
          infoWindow: InfoWindow(
            title: 'New Location',
            snippet: 'New Delivery Location',
          )));
    });
    _userpos = CameraPosition(
      target: LatLng(latitude, longitude),
      zoom: 14.4746,
    );
    _newhomeLocation();
  }

  //////camera position//////
  Future<void> _newhomeLocation() async {
    gmcontroller = await _controller.future;
    gmcontroller.animateCamera(CameraUpdate.newCameraPosition(_home));
    //Navigator.of(context).pop(false);
    //_loadMapDialog();
  }

  _getLocationfromlatlng(double lat, double lng, newSetState) async {
    final Geolocator geolocator = Geolocator()
      ..placemarkFromCoordinates(lat, lng);
    _currentPosition = await geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    //debugPrint('location: ${_currentPosition.latitude}');
    final coordinates = new Coordinates(lat, lng);
    var addresses =
        await Geocoder.local.findAddressesFromCoordinates(coordinates);
    var first = addresses.first;
    newSetState(() {
      curaddress = first.addressLine;
      if (curaddress != null) {
        latitude = _currentPosition.latitude;
        longitude = _currentPosition.longitude;
        return;
      }
    });
    setState(() {
      curaddress = first.addressLine;
      if (curaddress != null) {
        latitude = _currentPosition.latitude;
        longitude = _currentPosition.longitude;
        return;
      }
    });
  }

  void _onStoreCredit(bool newValue) => setState(() {
        _storeCredit = newValue;
        if (_storeCredit) {
          _updatePayment();
        } else {
          _updatePayment();
        }
      });

  _updateCart(int index, String op) {
    int curquantity = int.parse(cartData[index]['pquantity']);
    int quantity = int.parse(cartData[index]['cquantity']);
    if (op == "add") {
      quantity++;
      if (quantity > (curquantity - 2)) {
        Toast.show("Quantity not available", context,
            duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
        return;
      }
    }
    if (op == "remove") {
      quantity--;
      if (quantity == 0) {
        _deleteCart(index);
        return;
      }
    }
    String urlLoadJobs = server + "/php/updatecartrecord.php";
    http.post(urlLoadJobs, body: {
      "email": widget.user.email,
      "prodid": cartData[index]['pid'],
      "quantity": quantity.toString()
    }).then((res) {
      print(res.body);
      if (res.body == "success") {
        Toast.show("Cart Updated", context,
            duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
        _loadCart();
      } else {
        Toast.show("Failed", context,
            duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
      }
    }).catchError((err) {
      print(err);
    });
  }

  _deleteCart(int index) {
    showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        backgroundColor: Colors.purple[300],
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20.0))),
        title: new Text(
          'Delete item?',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        actions: <Widget>[
          MaterialButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                http.post(server + "/php/deletecartrecord.php", body: {
                  "email": widget.user.email,
                  "prodid": cartData[index]['pid'],
                }).then((res) {
                  print(res.body);

                  if (res.body == "success") {
                    _loadCart();
                  } else {
                    Toast.show("Failed", context,
                        duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
                  }
                }).catchError((err) {
                  print(err);
                });
              },
              child: Text(
                "Yes",
                style: TextStyle(
                  color: Colors.white,
                ),
              )),
          MaterialButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.white,
                ),
              )),
        ],
      ),
    );
  }

  //////loading data from cart database//////
  void _loadCart() {
    _weight = 0.0;
    _totalprice = 0.0;
    amountpayable = 0.0;
    deliverycharge = 0.0;

    ProgressDialog pr = new ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: false);
    pr.style(message: "Updating cart...");
    pr.show();

    String urlLoadJobs = server + "/php/loadcartrecord.php";
    http.post(urlLoadJobs, body: {
      "email": widget.user.email,
    }).then((res) {
      print(res.body);
      pr.dismiss();

      if (res.body == "Cart Empty") {
        //Navigator.of(context).pop(false);
        widget.user.quantity = "0";
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (BuildContext context) => MainPage(
                      user: widget.user,
                    )));
      }

      setState(() {
        var extractdata = json.decode(res.body);
        cartData = extractdata["cart"];
        for (int i = 0; i < cartData.length; i++) {
          _weight = double.parse(cartData[i]['pweight']) *
                  int.parse(cartData[i]['cquantity']) +
              _weight;
          _totalprice = double.parse(cartData[i]['yourprice']) + _totalprice;
        }
        _weight = _weight / 1000;
        amountpayable = _totalprice;

        print(_weight);
        print(_totalprice);
      });
    }).catchError((err) {
      print(err);
      pr.dismiss();
    });
    pr.dismiss();
  }

  //////get location//////
  _getLocation() async {
    final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
    _currentPosition = await geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    //debugPrint('location: ${_currentPosition.latitude}');
    final coordinates =
        new Coordinates(_currentPosition.latitude, _currentPosition.longitude);
    var addresses =
        await Geocoder.local.findAddressesFromCoordinates(coordinates);
    var first = addresses.first;
    setState(() {
      curaddress = first.addressLine;
      if (curaddress != null) {
        latitude = _currentPosition.latitude;
        longitude = _currentPosition.longitude;
        return;
      }
    });

    print("${first.featureName} : ${first.addressLine}");
  }
}
