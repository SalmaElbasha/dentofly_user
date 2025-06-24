import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/show_custom_snakbar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/response_model.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/domain/models/config_model.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/splash/controllers/splash_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/custom_themes.dart';
import 'package:flutter_sixvalley_ecommerce/utill/dimensions.dart';
import 'package:flutter_sixvalley_ecommerce/utill/images.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_app_bar_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_button_widget.dart';
import 'package:flutter_sixvalley_ecommerce/common/basewidget/custom_textfield_widget.dart';
import 'package:provider/provider.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  late TextEditingController _emailController;
  final GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    final authProvider = Provider.of<AuthController>(context, listen: false);
    authProvider.clearVerificationMessage();
    authProvider.setIsLoading = false;
    authProvider.setIsPhoneVerificationButttonLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    final configModel = Provider.of<SplashController>(context, listen: false).configModel!;

    return Scaffold(
      appBar: CustomAppBar(title: getTranslated('forget_password', context)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(50),
                child: Image.asset(Images.logoWithNameImage, height: 150, width: 150),
              ),
            ),
          ),
          Expanded(child: _buildEmailForm(configModel))
        ],
      ),
    );
  }

  Widget _buildEmailForm(ConfigModel configModel) {
    return Consumer<AuthController>(
      builder: (context, authProvider, _) {
        return Form(
          key: _emailFormKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Text(
                  getTranslated('forget_password', context)!,
                  style: textMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Text(
                getTranslated('enter_email_for_password_reset', context)!,
                style: titilliumRegular.copyWith(color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              CustomTextFieldWidget(
                controller: _emailController,
                inputType: TextInputType.emailAddress,
                labelText: getTranslated('email', context),
                isShowBorder: true,
              ),
              const SizedBox(height: 100),
              CustomButton(
                isLoading: authProvider.isLoading || authProvider.isForgotPasswordLoading,
                buttonText: getTranslated('send', context),
                onTap: () async {
                  if (_emailFormKey.currentState?.validate() ?? false) {
                    String email = _emailController.text.trim();

                    if (email.isEmpty) {
                      showCustomSnackBar(getTranslated('enter_email', context), context);
                      return;
                    }

                    ResponseModel? response = await authProvider.forgetPassword(
                      config: configModel,
                      phoneOrEmail: email,
                      type: 'email',
                    );

                    if (response != null && response.isSuccess) {
                      showCustomSnackBar(response.message, context, isError: false);
                    } else if (response != null) {
                      showCustomSnackBar(response.message, context);
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}