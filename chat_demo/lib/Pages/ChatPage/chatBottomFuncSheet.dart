import 'dart:convert';
import 'dart:io';

import 'package:chat_demo/Model/chatModel.dart';
import 'package:chat_demo/Model/chatRecordModel.dart';
import 'package:chat_demo/Model/sqliteModel/tchatlog.dart';
import 'package:chat_demo/Model/sqliteModel/tuser.dart';
import 'package:chat_demo/Pages/VideoChat/webRtcPage.dart';
import 'package:chat_demo/Provider/bottomRowAnimProvider.dart';
import 'package:chat_demo/Provider/chatRecordsProvider.dart';
import 'package:chat_demo/Provider/chooseFileProvider.dart';
import 'package:chat_demo/Provider/globalDataProvider.dart';
import 'package:chat_demo/Provider/goSocketProvider.dart';
import 'package:chat_demo/Provider/signalRProvider.dart';
import 'package:chat_demo/Provider/webRTCProvider.dart';
import 'package:chat_demo/Tools/StaticMembers.dart';
import 'package:chat_demo/Tools/sqliteHelper.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ChatBottomFuncSheet extends StatelessWidget {
  const ChatBottomFuncSheet({Key key, @required this.webRTCProvider,@required this.otherId})
      : super(key: key);
  final WebRTCProvider webRTCProvider;
  final String otherId;
  @override
  Widget build(BuildContext context) {
    double rpx = MediaQuery.of(context).size.width / 750;
    BottomRowAnimProvider provider =
        Provider.of<BottomRowAnimProvider>(context);
    ChooseFileProvider chooseFileProvider =
        Provider.of<ChooseFileProvider>(context);
    GoSocketProvider goSocketProvider = Provider.of<GoSocketProvider>(context);
    GlobalDataProvider globalDataProvider=Provider.of<GlobalDataProvider>(context);
    ChatRecordsProvider chatRecordsProvider=Provider.of<ChatRecordsProvider>(context);
    return Container(
        height: provider.bottomSheetHeight,
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
            child: Column(children: [
          // Divider(),
          Container(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                      child: IconButton(
                    icon: Icon(Icons.videocam),
                    onPressed: () async {
                      final file = await ImagePicker.pickVideo(
                          source: ImageSource.gallery);
                      if (file == null) {
                        return;
                      }
                      String filePath = file.path;
                      chooseFileProvider.updateFilePath(filePath);
                      String resultFrameImage =
                          chooseFileProvider.genTempFramePath();
                      String origPath = chooseFileProvider.genTempOrigPath();
                      String tempMp4File = chooseFileProvider.genTempMp4Path();
                      // File copied = await file.copy(origPath);

                      // String cmdMOV =
                      //     "-i ${copied.path} -vcodec copy -acodec copy $tempMp4File";
                      // await chooseFileProvider.runFFMpeg(cmdMOV);
                      String cmd =
                          '-i $filePath -f image2 -ss 00:00:00 -vframes 1 $resultFrameImage';
                      await chooseFileProvider.runFFMpeg(cmd);
                      var imgFile = File(resultFrameImage);
                      var bytes = imgFile.readAsBytesSync();
                      var sth = await decodeImageFromList(bytes);
                      var height = sth.height.toDouble();
                      var width = sth.width.toDouble();
                      double ratio = width / height;
                      double maxRatio = 3;
                      double minRatio = 1 / 3;
                      double maxWidth = 300 * rpx;
                      double maxHeight = 375 * rpx;
                      BoxFit fitType;
                      if (ratio >= maxRatio) {
                        fitType = BoxFit.fitHeight;
                        double scale = height / maxHeight;
                        height = height / scale;
                        width = height * maxRatio / scale;
                      } else if (ratio <= maxRatio && ratio >= 1) {
                        fitType = BoxFit.fitWidth;
                        double scale = width / maxWidth;
                        height = height / scale;
                        width = width / scale;
                      } else if (ratio >= minRatio && ratio < 1) {
                        fitType = BoxFit.fitHeight;
                        double scale = height / maxWidth;
                        height = height / scale;
                        width = width / scale;
                      } else {
                        fitType = BoxFit.fitWidth;
                        double scale = width / maxWidth;
                        height = height / scale;
                        width = width / scale;
                      }

                      TChatLog record = TChatLog(
                          contentType: CHATTYPE.IMAGE,
                          // imgFitType: fitType,
                          imgWidth: width,
                          imgHeight: height,
                          content: resultFrameImage,
                          videoPath: filePath,);
                      Tuser user=await SqliteHelper().getUserInfo(globalDataProvider.userId);
                      ChatModel model=ChatModel(user: user,contentModel: record);
                      goSocketProvider.chatRecordsProvider.updateChatRecordsInChat(model);
                      goSocketProvider.sendMessage(json.encode(model.toJson()), globalDataProvider.userId, otherId, CHATTYPE.IMAGE);
                    },
                  )),
                  Container(
                    child: IconButton(
                      icon: Icon(Icons.call),
                      onPressed: () {
                        webRTCProvider.createOffer();
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => WebRtcMainPage(
                                      webRtcProvider: webRTCProvider,
                                    )));
                      },
                    ),
                  )
                ],
              )
            ],
          ))
        ])));
  }
}
