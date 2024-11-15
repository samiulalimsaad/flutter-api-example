import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:chopper/chopper.dart';

part 'main.chopper.dart';

void main() {
  runApp(MyApp());
}

/// Main App
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

/// Home Screen
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Networking')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HttpScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue, // Set the button background color
              foregroundColor: Colors.white, // Set the text color
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('HTTP Example'),
          ),
          const SizedBox(height: 16), // Add space between buttons
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChopperScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, // Set the button background color
              foregroundColor: Colors.white, // Set the text color
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Chopper Example'),
          ),
        ],
      ),
    );
  }
}

/// HTTP Service
class HttpService {
  Future<List<Map<String, dynamic>>> fetchPosts() async {
    final url = Uri.parse('https://jsonplaceholder.typicode.com/posts');
    final response = await http.get(
      url,
      headers: {'Custom-Header': 'MyHttpHeader'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load posts');
    }
  }
}

/// HTTP Screen
class HttpScreen extends StatelessWidget {
  final HttpService _httpService = HttpService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HTTP Example')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _httpService.fetchPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final posts = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 4.0),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post['title'],
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          post['body'],
                          style: const TextStyle(
                            fontSize: 16.0,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

/// Chopper Service
@ChopperApi()
abstract class PostService extends ChopperService {
  @Get(path: '/posts')
  Future<Response<List<Map<String, dynamic>>>> getPosts();

  static PostService create() {
    final client = ChopperClient(
      baseUrl: Uri.parse('https://jsonplaceholder.typicode.com'),
      services: [_$PostService()],
      converter: CustomJsonConverter(),
      interceptors: [
        const HeadersInterceptor({'Custom-Header': 'MyChopperHeader'}),
        HttpLoggingInterceptor(),
      ],
    );
    return _$PostService(client);
  }
}

/// Chopper Screen
class ChopperScreen extends StatelessWidget {
  final PostService _postService = PostService.create();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chopper Example')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _postService.getPosts().then((res) => res.body!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final posts = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 4.0),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post['title'],
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          post['body'],
                          style: const TextStyle(
                            fontSize: 16.0,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

/// Custom JSON Converter for Chopper
class CustomJsonConverter extends JsonConverter {
  @override
  Response<ResultType> convertResponse<ResultType, Item>(Response response) {
    final dynamic jsonBody = jsonDecode(utf8.decode(response.bodyBytes));
    final body = _convertJson<ResultType>(jsonBody);
    return response.copyWith<ResultType>(body: body);
  }

  T _convertJson<T>(dynamic json) {
    if (T == List<Map<String, dynamic>>) {
      return (json as List).map((item) {
        return {
          ...item as Map<String, dynamic>,
          'title': (item['title'] as String).toUpperCase()
        };
      }).toList() as T;
    }
    return json as T;
  }
}
