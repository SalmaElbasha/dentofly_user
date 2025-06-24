import 'dart:developer';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/domain/models/address_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/widgets/code_picker_widget.dart';
import 'package:flutter_sixvalley_ecommerce/features/checkout/controllers/checkout_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/location/controllers/location_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/location/screens/select_location_screen.dart';
import 'package:flutter_sixvalley_ecommerce/features/profile/controllers/profile_contrroller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart' as config;
import 'package:flutter_sixvalley_ecommerce/helper/country_code_helper.dart';
import 'package:flutter_sixvalley_ecommerce/helper/velidate_check.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/address/controllers/address_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/color_resources.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/success_dialog_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_textfield_widget.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/domain/repositories/GovernateRepository.dart';
import '../../auth/domain/services/GovernateService.dart';
import '../../location/domain/models/place_details_model.dart';

class AddNewAddressScreen extends StatefulWidget {
  final bool isEnableUpdate;
  final bool fromCheckout;
  final AddressModel? address;
  final bool? isBilling;
  const AddNewAddressScreen({super.key, this.isEnableUpdate = false, this.address, this.fromCheckout = false, this.isBilling});

  @override
  State<AddNewAddressScreen> createState() => _AddNewAddressScreenState();
}

class _AddNewAddressScreenState extends State<AddNewAddressScreen> {
  final TextEditingController _contactPersonNameController = TextEditingController();
  final TextEditingController _contactPersonEmailController = TextEditingController();
  final TextEditingController _contactPersonNumberController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _AddressController = TextEditingController();
  final TextEditingController _countryCodeController = TextEditingController();
  final FocusNode _addressNode = FocusNode();
  final FocusNode _nameNode = FocusNode();
  final FocusNode _emailNode = FocusNode();
  final FocusNode _numberNode = FocusNode();
  final FocusNode _cityNode = FocusNode();
  final FocusNode _zipNode = FocusNode();
  GoogleMapController? _controller;
  CameraPosition? _cameraPosition;
  bool _updateAddress = true;
  Address? _address;
  String zip = '',  country = 'IN';
  late LatLng _defaut;
  LatLng? _initialPosition;
  double? userLat;
  double? userLng;
  Future<void> _handleAddressChange() async {
    String fullAddress = "${_cityController.text}, ${_AddressController.text}";

    if (fullAddress.trim().isEmpty) return;

    try {
      List<geo.Location> locations = await geo.locationFromAddress(fullAddress);
      if (locations.isNotEmpty && _controller != null) {
        LatLng newLatLng = LatLng(locations[0].latitude, locations[0].longitude);
        _controller!.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 16));
      }
    } catch (e) {
      print("Address lookup failed: $e");
    }
  }


  bool _isLoadingLocation = true;
  late final GovernateService governateService;
  final GlobalKey<FormState> _addressFormKey = GlobalKey();
  Future<void> _setCurrentLocation() async {
    try {
      Position position = await _determinePosition();
      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
        _cameraPosition = CameraPosition(target: _initialPosition!, zoom: 16);
        userLat = position.latitude;
        userLng = position.longitude;
        _isLoadingLocation = false;
      });
    } catch (e) {
      print('Error getting location: $e');

      setState(() {


        _isLoadingLocation = false;
      });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }
int? govId;
  @override
  void initState() {
    super.initState();
    _setCurrentLocation();
    _cityController.addListener(_handleAddressChange);
    _AddressController.addListener(_handleAddressChange);
    config.DefaultLocation? dLocation = Provider.of<SplashController>(context, listen: false).configModel?.defaultLocation;
    _defaut = LatLng(double.parse(dLocation?.lat ?? '0'), double.parse(dLocation?.lng ?? '0'));
    Future.microtask(() async {
      govId=await Provider.of<AddressController>(context, listen: false).getGovernatesIds(context);
      final prefs = await SharedPreferences.getInstance();
      governateService = GovernateService(governateRepo: GovernateRepository(sharedPreferences: prefs));
await Provider.of<AddressController>(context, listen: false).getGovernateDetails(govId??0);
    });



    if(widget.isBilling!){
      _address = Address.billing;
    }else{
      _address = Address.shipping;
    }

    Provider.of<AuthController>(context, listen: false).setCountryCode(CountryCode.fromCountryCode(Provider.of<SplashController>(context, listen: false).configModel!.countryCode!).dialCode!, notify: false);
    _countryCodeController.text = CountryCode.fromCountryCode(Provider.of<SplashController>(context, listen: false).configModel!.countryCode!).name??'Bangladesh';
    Provider.of<AddressController>(context, listen: false).getAddressType();
    Provider.of<AddressController>(context, listen: false).getRestrictedDeliveryCountryList();
    Provider.of<AddressController>(context, listen: false).getRestrictedDeliveryZipList();


    _checkPermission(() => Provider.of<LocationController>(context, listen: false).getCurrentLocation(context, true, mapController: _controller),context);
    if (widget.isEnableUpdate && widget.address != null) {
      _updateAddress = false;

      Provider.of<LocationController>(context, listen: false).updateMapPosition(CameraPosition(
          target: LatLng(
            (widget.address!.latitude != null && widget.address!.latitude != '0' && widget.address!.latitude != '') ?
            double.parse(widget.address!.latitude!) : _defaut.latitude,
            (widget.address!.longitude != null && widget.address!.longitude != '0' && widget.address!.longitude != '') ?
            double.parse(widget.address!.longitude!) : _defaut.longitude,
          )), true, widget.address!.address, context);
      _contactPersonNameController.text = '${widget.address?.contactPersonName}';
      _countryCodeController.text = '${widget.address?.country}';
      _contactPersonEmailController.text =  '${widget.address?.email}';
      // _contactPersonNumberController.text = '${widget.address?.phone}';
      _cityController.text = '${widget.address?.city}';
      _AddressController.text = '${widget.address?.zip}';
      if (widget.address!.addressType == 'Home') {
        Provider.of<AddressController>(context, listen: false).updateAddressIndex(0, false);
      } else if (widget.address!.addressType == 'Workplace') {
        Provider.of<AddressController>(context, listen: false).updateAddressIndex(1, false);
      } else {
        Provider.of<AddressController>(context, listen: false).updateAddressIndex(2, false);
      }
      String countryCode = CountryCodeHelper.getCountryCode(widget.address?.phone ?? '')!;
      Provider.of<AuthController>(context, listen: false).setCountryCode(countryCode, notify: false);
      String phoneNumberOnly = CountryCodeHelper.extractPhoneNumber(countryCode, widget.address?.phone ?? '');
      _contactPersonNumberController.text = phoneNumberOnly;

    }else {
      if(Provider.of<ProfileController>(context, listen: false).userInfoModel!=null){
        _contactPersonNameController.text = '${Provider.of<ProfileController>(context, listen: false).userInfoModel!.fName ?? ''}'
            ' ${Provider.of<ProfileController>(context, listen: false).userInfoModel!.lName ?? ''}';

        String countryCode = CountryCodeHelper.getCountryCode(Provider.of<ProfileController>(context, listen: false).userInfoModel!.phone ?? '')!;
        Provider.of<AuthController>(context, listen: false).setCountryCode(countryCode);
        String phoneNumberOnly = CountryCodeHelper.extractPhoneNumber(countryCode, Provider.of<ProfileController>(context, listen: false).userInfoModel!.phone ?? '');
        _contactPersonNumberController.text = phoneNumberOnly;
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: widget.isEnableUpdate ? getTranslated('update_address', context) : getTranslated('add_new_address', context)),
      body: SingleChildScrollView(
        child: Column(children: [
            Consumer<AddressController>(
              builder: (context, addressController, child) {
                if ( Provider.of<SplashController>(context , listen: false ). configModel !. deliveryCountryRestriction == 1  && addressController.restrictedCountryList.isNotEmpty ) {
                  _countryCodeController . text = addressController. restrictedCountryList [ 0 ];
                }
                return Consumer<LocationController>(
                  builder: (context, locationController, _) {
                    return Padding(padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                      child: Form(
                        key: _addressFormKey,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [


                          Padding(padding: const EdgeInsets.only(top: Dimensions.paddingSizeLarge),
                            child: CustomTextFieldWidget(
                              required: true,
                              prefixIcon: Images.user,
                              labelText: getTranslated('enter_contact_person_name', context),
                              hintText: getTranslated('enter_contact_person_name', context),
                              inputType: TextInputType.name,
                              controller: _contactPersonNameController,
                              focusNode: _nameNode,
                              nextFocus: _numberNode,
                              inputAction: TextInputAction.next,
                              capitalization: TextCapitalization.words,
                              validator: (value)=> ValidateCheck.validateEmptyText(value, 'contact_person_name_is_required'),
                            )),

                          const SizedBox(height: Dimensions.paddingSizeDefaultAddress),
                          Consumer<AuthController>(
                              builder: (context, authProvider,_) {
                                return CustomTextFieldWidget(
                                  required: true,
                                  labelText: getTranslated('phone', context),
                                  hintText: getTranslated('enter_mobile_number', context),
                                  controller: _contactPersonNumberController,
                                  focusNode: _numberNode,
                                  nextFocus: _emailNode,
                                  showCodePicker: true,
                                  countryDialCode: authProvider.countryDialCode,
                                  onCountryChanged: (CountryCode countryCode) {
                                    authProvider.countryDialCode = countryCode.dialCode!;
                                    authProvider.setCountryCode(countryCode.dialCode!);
                                  },
                                  isAmount: true,
                                  validator: (value)=> ValidateCheck.validateEmptyText(value, "phone_must_be_required"),
                                  inputAction: TextInputAction.next,
                                  inputType: TextInputType.phone,
                                );
                              }
                          ),
                          const SizedBox(height: Dimensions.paddingSizeDefaultAddress),

                          if(!Provider.of<AuthController>(context, listen: false).isLoggedIn())
                          CustomTextFieldWidget(
                            required: true,
                            prefixIcon: Images.email,
                            labelText: getTranslated('email', context),
                            hintText: getTranslated('enter_contact_person_email', context),
                            inputType: TextInputType.emailAddress,
                            controller: _contactPersonEmailController,
                            focusNode: _emailNode,
                            nextFocus: _addressNode,
                            inputAction: TextInputAction.next,
                            capitalization: TextCapitalization.words,
                            validator: (value)=> ValidateCheck.validateEmail(value),

                          ),
                          const SizedBox(height: Dimensions.paddingSizeDefaultAddress),

                          Consumer<AddressController>(
                              builder: (context, addressController, child) {
                    return Container(
                      padding: const EdgeInsets.only(left: 12, right: 12,top: 12),
                      height: MediaQuery.of(context).size.width / 8,
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        color: ColorResources.imageBg,
                        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                      ),
                      child:   Text(addressController.note??"", style: textRegular.copyWith(
                        color: ColorResources.black,
                        fontSize: Dimensions.fontSizeSmall,
                      )),
                    );}),
                    Provider.of<SplashController>(context, listen: false).configModel!.mapApiStatus == 1
                    ? SizedBox(
                    height: MediaQuery.of(context).size.width / 2,
                    width: MediaQuery.of(context).size.width,
                    child: ClipRRect(
                    borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                    child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                    GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                    target: widget.isEnableUpdate
                    ? LatLng(
                    (widget.address?.latitude != null && widget.address!.latitude != '0' && widget.address!.latitude!.isNotEmpty)
                    ? double.parse(widget.address!.latitude!)
                        : _defaut.latitude,
                    (widget.address?.longitude != null && widget.address!.longitude != '0' && widget.address!.longitude!.isNotEmpty)
                    ? double.parse(widget.address!.longitude!)
                        : _defaut.longitude,
                    )
                        : LatLng(locationController.position.latitude, locationController.position.longitude),
                    zoom: 16,
                    ),
                    zoomControlsEnabled: false,
                    compassEnabled: false,
                    indoorViewEnabled: true,
                    mapToolbarEnabled: false,
                    onMapCreated: (GoogleMapController controller) {
                    _controller = controller;
                    if (!widget.isEnableUpdate && _controller != null) {
                    locationController.getCurrentLocation(context, true, mapController: _controller);
                    }
                    },
                    onCameraMove: (position) => _cameraPosition = position,
                    onCameraIdle: () {
                    if (_updateAddress) {
                    locationController.updateMapPosition(_cameraPosition, true, null, context);
                    } else {
                    _updateAddress = true;
                    }
                    },
                    onTap: (latLng) {
                    // Instead of navigating to another screen, show a dialog or snackbar
                    showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                    title: const Text('Select Location'),
                    content: const Text('Location selection is currently disabled or handled on this screen.'),
                    actions: [
                    TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                    ),
                    ],
                    ),
                    );

                    // Or update the position directly if needed, e.g.:
                    // locationController.updateMapPosition(CameraPosition(target: latLng, zoom: 16), true, null, context);
                    },
                    ),

                    // Loading overlay spinner
                    if (locationController.loading)
                    Center(
                    child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                    ),
                    ),

                    // Fixed marker icon centered on map view
                    Container(
                    width: MediaQuery.of(context).size.width,
                    alignment: Alignment.center,
                    height: MediaQuery.of(context).size.height,
                    child: Icon(Icons.location_on, size: 40, color: Theme.of(context).primaryColor),
                    ),

                    // Fullscreen button that shows a snackbar
                    Positioned(
                    top: 10,
                    right: 0,
                    child: InkWell(
                    onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fullscreen map feature is disabled or handled here.')),
                    );
                    },
                    child: Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.only(right: Dimensions.paddingSizeLarge),
                    decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                    color: Colors.white,
                    ),
                    child: Icon(Icons.fullscreen, color: Theme.of(context).primaryColor, size: 20),
                    ),
                    ),
                    ),
                    ],
                    ),
                    ),
                    )
                        : const SizedBox(),



                    Padding(
                              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
                              child: Text(getTranslated('label_us', context)!, style: textRegular.copyWith(
                                color: ColorResources.getHint(context),
                                fontSize: Dimensions.fontSizeLarge,
                              )),
                            ),

                            SizedBox(height: 50,
                              child: RepaintBoundary(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: addressController.addressTypeList.length,
                                  itemBuilder: (context, index) => InkWell(
                                    onTap: () => addressController.updateAddressIndex(index, true),
                                    child: Container(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault, horizontal: Dimensions.paddingSizeLarge),
                                      margin: const EdgeInsets.only(right: 17),
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                                          border: Border.all(color: addressController.selectAddressIndex == index ?
                                          Theme.of(context).primaryColor : Theme.of(context).primaryColor.withValues(alpha:.125))),
                                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                        SizedBox(width: 20, child: Image.asset(addressController.addressTypeList[index].icon,
                                            color: addressController.selectAddressIndex == index ?
                                        Theme.of(context).primaryColor : Theme.of(context).primaryColor.withValues(alpha:.35))),
                                        const SizedBox(width: Dimensions.paddingSizeSmall,),
                                        Text(getTranslated(addressController.addressTypeList[index].title, context)!,
                                            style: textRegular.copyWith())])))),
                              )),


                            Padding(padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                              child: SizedBox(height: 50,
                                child: Row(children: <Widget>[
                                  Row(children: [
                                      Radio<Address>(
                                        value: Address.shipping,
                                        groupValue: _address,
                                        onChanged: (Address? value) {
                                          setState(() {_address = value;});}),
                                      Text(getTranslated('shipping_address', context)??'', style: textRegular.copyWith(fontSize: Dimensions.fontSizeLarge),),]),


                                  Row(children: [
                                    Radio<Address>(
                                      value: Address.billing,
                                      groupValue: _address,
                                      onChanged: (Address? value) {
                                        setState(() {
                                          _address = value;});}),
                                      Text(getTranslated('billing_address', context)??'', style: textRegular.copyWith(fontSize: Dimensions.fontSizeLarge))])]))),


                          ...[

                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),


                            Consumer<AddressController>(
                              builder: (context, addressController, child) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                                    Text(getTranslated('Delivery Time', context)!, style: textRegular.copyWith(
                                      color: ColorResources.black,
                                      fontSize: Dimensions.fontSizeSmall,
                                    )),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      margin: const EdgeInsets.only(
                                        left: Dimensions.marginSizeDefault - 15,
                                        right: Dimensions.marginSizeDefault - 15,
                                        top: Dimensions.marginSizeSmall,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          isExpanded: true,
                                          hint: Text(
                                            "Choose delivery time",
                                            style: textRegular.copyWith(
                                              fontSize: Dimensions.fontSizeDefault,
                                              color: Theme.of(context).hintColor,
                                            ),
                                          ),
                                          value: addressController.selectedDate,
                                          items: addressController.delivery?.map((time) {
                                            return DropdownMenuItem<String>(
                                              value: time,
                                              child: Text(
                                                time,
                                                style: textRegular.copyWith(
                                                  fontSize: Dimensions.fontSizeDefault,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            if (value != null) {
                                              addressController.selectedDate = value;
                                              addressController.todayOrTomorrow.text =
                                                  addressController.getDayLabel(addressController.selectedDate ?? "");
                                              addressController.note=addressController.governate?.note;
                                            }
                                            setState(() {

                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: Dimensions.paddingSizeDefaultAddress),
                            Text(getTranslated('Delivery Date', context)!, style: textRegular.copyWith(
                              color: ColorResources.black,
                              fontSize: Dimensions.fontSizeSmall,
                            )),
                            const SizedBox(height: Dimensions.paddingSizeDefaultAddress),
                            CustomTextFieldWidget(
                              labelText: getTranslated('Delivery Date', context),
                              hintText: getTranslated('Delivery Date', context),
                              inputType: TextInputType.text,
                              inputAction: TextInputAction.next,
                              required: false,
                              nextFocus: _cityNode,
                              controller:  Provider.of<AddressController>(context, listen: false).todayOrTomorrow,
                              readOnly: true,
                            ),
                          ],




                          const SizedBox(height: Dimensions.paddingSizeDefaultAddress),
                            CustomTextFieldWidget(
                              labelText: getTranslated('city', context),
                              hintText: getTranslated('city', context),
                              inputType: TextInputType.streetAddress,
                              inputAction: TextInputAction.next,
                              focusNode: _cityNode,
                                required: true,
                              nextFocus: _addressNode,
                              prefixIcon: Images.city,
                              controller: _cityController,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'المدينة مطلوبة';
                                }
                                return null;
                              },

                            ),
                          const SizedBox(height: Dimensions.paddingSizeDefaultAddress),



                          CustomTextFieldWidget(labelText: getTranslated('delivery_address', context),
                            hintText: getTranslated('usa', context),
                            inputType: TextInputType.streetAddress,
                            inputAction: TextInputAction.next,
                            focusNode: _addressNode,
                            prefixIcon: Images.address,
                            required: true,
                            nextFocus: _zipNode,
                            controller:_AddressController,
                            validator: (value)=> ValidateCheck.validateEmptyText(value, 'address_is_required'),


                          ),
                          const SizedBox(height: Dimensions.paddingSizeDefaultAddress),
                          Provider.of<SplashController>(context, listen: false).configModel!.deliveryZipCodeAreaRestriction == 0?
                          CustomTextFieldWidget(
                            labelText: getTranslated('zip', context),
                            hintText: getTranslated('zip', context),
                            inputAction: TextInputAction.done,
                            focusNode: _zipNode,
                            required: true,
                            prefixIcon: Images.city,
                            controller: _zipCodeController,
                            validator: (value)=> ValidateCheck.validateEmptyText(value, 'zip_code_is_required'),

                          ):

                          Container(width: MediaQuery.of(context).size.width,
                            decoration: BoxDecoration(color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(width: .1, color: Theme.of(context).hintColor.withValues(alpha:0.1))),
                            child: DropdownButtonFormField2<String>(
                              isExpanded: true,
                              isDense: true,
                              decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(5))),
                              hint:  Row(children: [
                                Image.asset(Images.city),
                                const SizedBox(width: Dimensions.paddingSizeSmall,),
                                Text(_zipCodeController.text, style: textRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge!.color)),
                              ],
                              ),
                              items: addressController.restrictedZipList.map((item) => DropdownMenuItem<String>(
                                  value: item.zipcode, child: Text(item.zipcode!, style: textRegular.copyWith(fontSize: Dimensions.fontSizeSmall)))).toList(),
                              onChanged: (value) {
                                _zipCodeController.text = value!;

                              },
                              buttonStyleData: const ButtonStyleData(padding: EdgeInsets.only(right: 8),),
                              iconStyleData: IconStyleData(
                                  icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).hintColor), iconSize: 24),
                              dropdownStyleData: DropdownStyleData(
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(5))),
                              menuItemStyleData: const MenuItemStyleData(padding: EdgeInsets.symmetric(horizontal: 16)),
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeDefaultAddress),

                          Container(height: 50.0,
                            margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                            child: CustomButton(
                              isLoading: addressController.isLoading,
                              buttonText: widget.isEnableUpdate ? getTranslated('update_address', context) : getTranslated('save_location', context),
                              onTap: locationController.loading ? null : () async{

                                if(_addressFormKey.currentState?.validate() ?? false) {
                                  int allowedGovernorateIds = await Provider.of<AddressController>(context, listen: false).getGovernatesIds(context);
                                  AddressModel addressModel = AddressModel(
                                      addressType: addressController.addressTypeList[addressController.selectAddressIndex].title,
                                      contactPersonName: _contactPersonNameController.text,
                                      phone: '${Provider.of<AuthController>(context, listen: false).countryDialCode}${_contactPersonNumberController.text.trim()}',
                                      email: _contactPersonEmailController.text.trim(),
                                      city: _cityController.text,
                                      zip: _zipCodeController.text,
                                      country:  _countryCodeController.text,
                                      guestId: Provider.of<AuthController>(context, listen: false).getGuestToken(),
                                      isBilling: _address == Address.billing,
                                      address: _AddressController.text,
                                      latitude: widget.isEnableUpdate ? locationController.position.latitude.toString() : locationController.position.latitude.toString(),
                                      longitude: widget.isEnableUpdate ? locationController.position.longitude.toString() : locationController.position.longitude.toString(),
                                    governorateId:     allowedGovernorateIds                       );


                                  if (widget.isEnableUpdate) {
                                    addressModel.id = widget.address!.id;
                                    addressController.updateAddress(context, addressModel: addressModel, addressId: addressModel.id);

                                  }else if(_countryCodeController.text.trim().isEmpty){
                                    showCustomSnackBar('${getTranslated('country_is_required', context)}', context);
                                  } else {
                                    addressController.addAddress(addressModel).then((value) {
                                      if (value.response?.statusCode == 200 ) {
                                        Navigator.pop(context);
                                        if (widget.fromCheckout) {
                                          Provider.of<CheckoutController>(context, listen: false).setAddressIndex(0);
                                        }
                                      }
                                    });
                                  }

                                }
                              },
                            ),
                          ),


                        ]),
                      ),
                    );
                  }
                );
              },
            ),
          ],
        )
      ),
    );
  }
  void _checkPermission(Function callback, BuildContext context) async {
    LocationPermission permission = await Geolocator.requestPermission();
    if(permission == LocationPermission.denied || permission == LocationPermission.whileInUse) {
      InkWell(onTap: () async{
        Navigator.pop(context);
        await Geolocator.requestPermission();
        _checkPermission(callback,  Get.context!);
        },
          child: AlertDialog(content: SuccessDialog(icon: Icons.location_on_outlined, title: '',
              description: getTranslated('you_denied', Get.context!))));
    }else if(permission == LocationPermission.deniedForever) {
      InkWell(onTap: () async{
        if(context.mounted){}
        Navigator.pop(context);
        await Geolocator.openAppSettings();
        _checkPermission(callback, Get.context!);
        },
          child: AlertDialog(content: SuccessDialog(icon: Icons.location_on_outlined, title: '',
              description: getTranslated('you_denied', Get.context!))));
    }else {
      callback();
    }
  }
}

enum Address {shipping, billing }

