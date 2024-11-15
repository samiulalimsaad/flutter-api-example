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
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HttpScreen()),
              );
            },
            child: const Text('HTTP Example'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChopperScreen()),
              );
            },
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
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(posts[index]['title']),
                  subtitle: Text(posts[index]['body']),
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
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return ListTile(
                  title: Text(post['title']),
                  subtitle: Text(post['body']),
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
        return {...item as Map<String, dynamic>, 'title': (item['title'] as String).toUpperCase()};
      }).toList() as T;
    }
    return json as T;
  }
}
