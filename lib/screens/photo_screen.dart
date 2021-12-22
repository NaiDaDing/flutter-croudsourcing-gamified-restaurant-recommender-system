import 'package:flutter/material.dart';

class PhotoScreen extends StatelessWidget {
  static const routeName = '/photo';
  final List photos;
  final String url;
  final String situation;

  PhotoScreen({this.photos, this.url, this.situation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('相關照片')),
      body: situation == 'single_photo'
          ? Center(child: Image.network(url))
          : ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(10.0),
              children: [
                ListView.builder(
                    physics: ScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      return Container(
                        padding: EdgeInsets.all(10),
                        child: Card(
                          shape: Border.all(
                            width: 5,
                          ),
                          elevation: 10,
                          child: Column(
                            children: [
                              Image.network(photos[index]['url']),
                              SizedBox(height: 10),
                              Text(
                                photos[index]['timestamp'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              SizedBox(height: 10),
                            ],
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          ),
                        ),
                      );
                    }),
              ],
            ),
    );
  }
}
