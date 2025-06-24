import 'package:file_picker/file_picker.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/dio/dio_client.dart';
import 'package:flutter_sixvalley_ecommerce/data/datasource/remote/exception/api_error_handler.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/domain/models/message_body.dart';
import 'package:flutter_sixvalley_ecommerce/data/model/api_response.dart';
import 'package:flutter_sixvalley_ecommerce/features/chat/domain/repositories/chat_repository_interface.dart';
import 'package:flutter_sixvalley_ecommerce/main.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
class ChatRepository implements ChatRepositoryInterface {
  final DioClient? dioClient;
  ChatRepository({required this.dioClient});



  @override
  Future<ApiResponse> getChatList(String type, int offset) async {
    try {
      final response = await dioClient!.get('${AppConstants.chatInfoUri}$type?limit=10&offset=$offset');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }


  @override
  Future<ApiResponse> searchChat(String type, String search) async {
    try {
      final response = await dioClient!.get('${AppConstants.searchChat}$type?search=$search');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }

  @override
  Future<ApiResponse> getMessageList(String type, int? id,int offset) async {
    try {
      final response = await dioClient!.get('${AppConstants.messageUri}$type/$id?limit=3000&offset=$offset');
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }



  @override
  Future<ApiResponse> seenMessage(int id, String type) async {
    try {
      final response = await dioClient!.post('${AppConstants.seenMessageUri}$type',
          data: {'id':id});
      return ApiResponse.withSuccess(response);
    } catch (e) {
      return ApiResponse.withError(ApiErrorHandler.getMessage(e));
    }
  }



  @override


  Future<http.StreamedResponse> sendMessage(
      MessageBody messageBody,
      String type,
      List<XFile?> files,
      List<PlatformFile>? platformFiles,
      ) async {
    final Uri uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.sendMessageUri}$type');
    final request = http.MultipartRequest('POST', uri);

    // Headers
    final token = Provider.of<AuthController>(Get.context!, listen: false).getUserToken();
    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    // Fields
    request.fields['id'] = messageBody.id.toString();
    request.fields['message'] = messageBody.message ?? '';

    // Handle XFile
    for (final xfile in files) {
      if (xfile == null) continue;

      final fileName = p.basename(xfile.path);
      final fileExt = p.extension(xfile.path).toLowerCase(); // e.g. ".pdf", ".jpg"

      final bytes = await xfile.readAsBytes();
      final isImage = ['.jpg', '.jpeg', '.png'].contains(fileExt);

      final multipart = http.MultipartFile.fromBytes(
        isImage ? 'image[]' : 'file[]',
        bytes,
        filename: fileName,
        contentType: isImage
            ? MediaType('image', fileExt == '.jpg' ? 'jpeg' : fileExt.replaceFirst('.', ''))
            : MediaType('application', 'octet-stream'),
      );
      request.files.add(multipart);
    }

    // Handle PlatformFile
    if (platformFiles != null) {
      for (final file in platformFiles) {
        final fileName = file.name;
        final fileExt = p.extension(fileName).toLowerCase();
        final isImage = ['.jpg', '.jpeg', '.png'].contains(fileExt);

        final multipart = file.readStream != null
            ? http.MultipartFile(
          isImage ? 'image[]' : 'file[]',
          file.readStream!,
          file.size,
          filename: fileName,
        )
            : http.MultipartFile.fromBytes(
          isImage ? 'image[]' : 'file[]',
          file.bytes!,
          filename: fileName,
        );

        request.files.add(multipart);
      }
    }
    debugPrint('======= Final Multipart Request Debug =======');
    debugPrint('Headers: ${request.headers}');
    debugPrint('Fields: ${request.fields}');

    for (var file in request.files) {
      debugPrint('📎 File Field Name: ${file.field}');
      debugPrint('📎 Filename: ${file.filename}');
      debugPrint('📎 ContentType: ${file.contentType}');
    }
    debugPrint('======= END Multipart Request Debug =======');

    // Send
    final response = await request.send();

    if (kDebugMode) {
      final responseStr = await response.stream.bytesToString();
      debugPrint('Response code: ${response.statusCode}');
      debugPrint('Response body: $responseStr');
    }

    return response;
  }




  @override
  Future add(value) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future delete(int id) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future get(String id) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) {
    // TODO: implement getList
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int id) {
    // TODO: implement update
    throw UnimplementedError();
  }


}