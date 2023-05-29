import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(ReviewsApp());
}

class ReviewsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reviews App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  List<dynamic> _places = [];
  List<String> _photos = [];
  List<dynamic> _reviews = [];

  String apiKey = 'AIzaSyCF058kgbZub2rD0Xxe-hHgtGycX49LVoU';

  Future<void> _searchPlaces(String query) async {
    var url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$apiKey&language=es';

    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        _places = data['predictions'];
      });
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    var url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey&language=es';

    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        _photos = data['result']['photos']
            .map<String>((photo) => 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${photo['photo_reference']}&key=$apiKey')
            .toList();
        _reviews = data['result']['reviews'];
      });
    }

  }

  Future<void> _likeReview(int index) async {
    var reviewId = _reviews[index]['author_url'].split('/').last;

    var likeUrl = 'https://maps.googleapis.com/maps/api/place/like/json?placeid=$reviewId&key=$apiKey';

    var response = await http.post(Uri.parse(likeUrl));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        _reviews[index]['likes'] = data['result']['likes'];
      });
    }
  }

  Future<void> _addComment(int index, String comment) async {
    var reviewId = _reviews[index]['author_url'].split('/').last;

    var commentUrl = 'https://maps.googleapis.com/maps/api/place/add/review/json?placeid=$reviewId&key=$apiKey';

    var requestBody = {
      'language': 'es',
      'rating': 0, // Puntuación deseada para el comentario
      'comment': comment,
    };

    var response = await http.post(Uri.parse(commentUrl), body: jsonEncode(requestBody));

    if (response.statusCode == 200) {
      // Lógica para manejar la respuesta exitosa
      // Puede ser una notificación al usuario o cualquier otra acción deseada
    } else {
      // Lógica para manejar errores en la solicitud
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews App'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar lugar',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    _searchPlaces(_searchController.text);
                    setState(() {
                      _places = [];
                    });
                  },
                ),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _searchPlaces(value);
                } else {
                  setState(() {
                    _places = [];
                  });
                }
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _places.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_places[index]['description']),
                        onTap: () {
                          _getPlaceDetails(_places[index]['place_id']);
                          setState(() {
                            _places = [];
                          });
                        },
                      );
                    },
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: 200,
                    child: ListView.builder(
                      itemCount: _photos.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return Dialog(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      _photos[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                _photos[index],
                                width: 300,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(_reviews[index]['profile_photo_url']),
                              ),
                              title: Text(_reviews[index]['author_name']),
                              subtitle: RatingBarIndicator(
                                rating: _reviews[index]['rating'].toDouble(),
                                itemBuilder: (context, index) => Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                itemCount: 5,
                                itemSize: 20.0,
                                direction: Axis.horizontal,
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.thumb_up),
                                color: Colors.blue,
                                onPressed: () {
                                  _likeReview(index);
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Text(_reviews[index]['text']),
                            ),
                            Divider(),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 10),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return CommentDialog(
                                onCommentSubmitted: (comment) {
                                  _addComment(_reviews.length - 1, comment);
                                },
                              );
                            },
                          );
                        },
                        child: Text('Agregar comentario'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CommentDialog extends StatefulWidget {
  final Function(String) onCommentSubmitted;

  CommentDialog({required this.onCommentSubmitted});

  @override
  _CommentDialogState createState() => _CommentDialogState();
}

class _CommentDialogState extends State<CommentDialog> {
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Comentario',
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                widget.onCommentSubmitted(_commentController.text);
                Navigator.pop(context);
              },
              child: Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }
}
