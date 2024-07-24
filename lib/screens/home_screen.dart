import 'package:dars82_graphql/utils/constants/products_graphql_queries.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Products"),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                onPressed: () {
                  _showAddProductDialog(context);
                },
                icon: const Icon(Icons.add),
              );
            },
          ),
        ],
      ),
      body: Query(
        options: QueryOptions(
          document: gql(getProducts),
        ),
        builder: (result, {fetchMore, refetch}) {
          if (result.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (result.hasException) {
            return Center(
              child: Text(result.exception.toString()),
            );
          }

          List products = result.data!['products'];

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (ctx, index) {
              final product = products[index];
              return ListTile(
                title: Text(product['title'] ?? 'No Title'),
                subtitle: Text(product['description'] ?? 'No Description'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _showEditProductDialog(context, product, refetch!);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        GraphQLProvider.of(context).value.mutate(
                              MutationOptions(
                                document: gql(deleteProduct),
                                variables: {"id": product['id']},
                                onCompleted: (data) {
                                  print(data);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Product deleted'),
                                    ),
                                  );
                                  refetch!();
                                },
                                onError: (error) {
                                  print(error!.linkException);
                                },
                              ),
                            );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String title = '';
    String description = '';
    double price = 0;
    int categoryId = 0;
    String imageUrl = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Product"),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Title"),
                    onSaved: (value) {
                      title = value!;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Description"),
                    onSaved: (value) {
                      description = value!;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Price"),
                    keyboardType: TextInputType.number,
                    onSaved: (value) {
                      price = double.parse(value!);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a price';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Category ID"),
                    keyboardType: TextInputType.number,
                    onSaved: (value) {
                      categoryId = int.parse(value!);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a category ID';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Image URL"),
                    onSaved: (value) {
                      imageUrl = value!;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an image URL';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  List<String> images = [imageUrl];

                  GraphQLProvider.of(context).value.mutate(
                        MutationOptions(
                          document: gql(addProduct),
                          variables: {
                            "title": title,
                            "description": description,
                            "categoryId": categoryId,
                            "price": price,
                            "images": images,
                          },
                          onCompleted: (data) {
                            print(data);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Product added')),
                            );
                            Navigator.of(context).pop();
                            final query =
                                GraphQLProvider.of(context).value.query(
                                      QueryOptions(
                                        document: gql(getProducts),
                                      ),
                                    );
                            query.then((result) {});
                          },
                          onError: (error) {
                            print(error!.linkException);
                          },
                        ),
                      );
                }
              },
              child: const Text("Add"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  void _showEditProductDialog(
      BuildContext context, Map<String, dynamic> product, Function refetch) {
    final _formKey = GlobalKey<FormState>();
    String title = product['title'] ?? '';
    String description = product['description'] ?? '';
    double price = product['price'] is int
        ? (product['price'] as int).toDouble()
        : product['price'] ?? 0.0;
    int categoryId = product['category']?['id'] ?? 0;
    String imageUrl =
        product['images']?.isNotEmpty == true ? product['images'][0] : '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Product"),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    initialValue: title,
                    decoration: const InputDecoration(labelText: "Title"),
                    onSaved: (value) {
                      title = value!;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    initialValue: description,
                    decoration: const InputDecoration(labelText: "Description"),
                    onSaved: (value) {
                      description = value!;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    initialValue: price.toString(),
                    decoration: const InputDecoration(labelText: "Price"),
                    keyboardType: TextInputType.number,
                    onSaved: (value) {
                      price = double.parse(value!);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a price';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    initialValue: categoryId.toString(),
                    decoration: const InputDecoration(labelText: "Category ID"),
                    keyboardType: TextInputType.number,
                    onSaved: (value) {
                      categoryId = int.parse(value!);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a category ID';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    initialValue: imageUrl,
                    decoration: const InputDecoration(labelText: "Image URL"),
                    onSaved: (value) {
                      imageUrl = value!;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an image URL';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  List<String> images = [imageUrl];

                  GraphQLProvider.of(context).value.mutate(
                        MutationOptions(
                          document: gql(editProduct),
                          variables: {
                            "id": product['id'],
                            "title": title,
                            "description": description,
                            "categoryId": categoryId,
                            "price": price,
                            "images": images,
                          },
                          onCompleted: (data) {
                            print(data);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Product edited')),
                            );
                            Navigator.of(context).pop();
                            refetch();
                          },
                          onError: (error) {
                            print(error!.linkException);
                          },
                        ),
                      );
                }
              },
              child: const Text("Save"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }
}
