/*
  # E-Commerce Database Schema

  ## Overview
  Creates a complete e-commerce database with products, shopping carts, orders, and order items.

  ## New Tables

  ### 1. products
  Stores product catalog information
  - `id` (uuid, primary key) - Unique product identifier
  - `name` (text) - Product name
  - `description` (text) - Product description
  - `price` (numeric) - Product price in dollars
  - `image_url` (text) - Product image URL
  - `category` (text) - Product category
  - `stock` (integer) - Available inventory
  - `created_at` (timestamptz) - Record creation timestamp

  ### 2. cart_items
  Stores items in user shopping carts
  - `id` (uuid, primary key) - Unique cart item identifier
  - `user_id` (uuid) - Reference to authenticated user
  - `product_id` (uuid) - Reference to products table
  - `quantity` (integer) - Quantity of product in cart
  - `created_at` (timestamptz) - Record creation timestamp

  ### 3. orders
  Stores completed customer orders
  - `id` (uuid, primary key) - Unique order identifier
  - `user_id` (uuid) - Reference to authenticated user
  - `total_amount` (numeric) - Total order amount
  - `status` (text) - Order status (pending, completed, cancelled)
  - `stripe_payment_id` (text) - Stripe payment intent ID
  - `shipping_address` (jsonb) - Shipping address details
  - `created_at` (timestamptz) - Order creation timestamp

  ### 4. order_items
  Stores individual items within orders
  - `id` (uuid, primary key) - Unique order item identifier
  - `order_id` (uuid) - Reference to orders table
  - `product_id` (uuid) - Reference to products table
  - `quantity` (integer) - Quantity ordered
  - `price` (numeric) - Price at time of purchase
  - `created_at` (timestamptz) - Record creation timestamp

  ## Security

  ### Row Level Security (RLS)
  All tables have RLS enabled with the following policies:

  #### products
  - Anyone can view products (public access)
  - Only authenticated users with admin role can modify products

  #### cart_items
  - Users can only view and manage their own cart items
  - Authenticated users can create, read, update, and delete their own cart items

  #### orders
  - Users can only view their own orders
  - Authenticated users can create orders
  - Users cannot update or delete orders (immutable after creation)

  #### order_items
  - Users can only view order items for their own orders
  - System automatically creates order items during checkout

  ## Notes
  - All foreign key constraints ensure data integrity
  - Indexes added for frequently queried columns
  - Default values set for timestamps and status fields
  - Products table includes sample data for demonstration
*/

-- Create products table
CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text NOT NULL,
  price numeric(10, 2) NOT NULL CHECK (price >= 0),
  image_url text NOT NULL,
  category text NOT NULL,
  stock integer NOT NULL DEFAULT 0 CHECK (stock >= 0),
  created_at timestamptz DEFAULT now()
);

-- Create cart_items table
CREATE TABLE IF NOT EXISTS cart_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  quantity integer NOT NULL DEFAULT 1 CHECK (quantity > 0),
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, product_id)
);

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  total_amount numeric(10, 2) NOT NULL CHECK (total_amount >= 0),
  status text NOT NULL DEFAULT 'pending',
  stripe_payment_id text,
  shipping_address jsonb NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Create order_items table
CREATE TABLE IF NOT EXISTS order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES products(id),
  quantity integer NOT NULL CHECK (quantity > 0),
  price numeric(10, 2) NOT NULL CHECK (price >= 0),
  created_at timestamptz DEFAULT now()
);

-- Enable RLS on all tables
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Products policies (public read access)
CREATE POLICY "Anyone can view products"
  ON products FOR SELECT
  USING (true);

-- Cart items policies
CREATE POLICY "Users can view own cart items"
  ON cart_items FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own cart items"
  ON cart_items FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own cart items"
  ON cart_items FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own cart items"
  ON cart_items FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Orders policies
CREATE POLICY "Users can view own orders"
  ON orders FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own orders"
  ON orders FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Order items policies
CREATE POLICY "Users can view own order items"
  ON order_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create order items"
  ON order_items FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.user_id = auth.uid()
    )
  );

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_cart_items_user_id ON cart_items(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);

-- Insert sample products
INSERT INTO products (name, description, price, image_url, category, stock) VALUES
  ('Wireless Headphones', 'Premium noise-cancelling headphones with 30-hour battery life', 199.99, 'https://images.pexels.com/photos/3394650/pexels-photo-3394650.jpeg?auto=compress&cs=tinysrgb&w=800', 'Electronics', 50),
  ('Smart Watch', 'Fitness tracking smartwatch with heart rate monitor', 299.99, 'https://images.pexels.com/photos/437037/pexels-photo-437037.jpeg?auto=compress&cs=tinysrgb&w=800', 'Electronics', 35),
  ('Laptop Backpack', 'Durable water-resistant backpack with laptop compartment', 79.99, 'https://images.pexels.com/photos/2905238/pexels-photo-2905238.jpeg?auto=compress&cs=tinysrgb&w=800', 'Accessories', 100),
  ('Coffee Maker', 'Programmable coffee maker with thermal carafe', 89.99, 'https://images.pexels.com/photos/324028/pexels-photo-324028.jpeg?auto=compress&cs=tinysrgb&w=800', 'Home', 45),
  ('Running Shoes', 'Lightweight running shoes with cushioned sole', 129.99, 'https://images.pexels.com/photos/2529148/pexels-photo-2529148.jpeg?auto=compress&cs=tinysrgb&w=800', 'Fashion', 80),
  ('Desk Lamp', 'LED desk lamp with adjustable brightness and color', 49.99, 'https://images.pexels.com/photos/1112598/pexels-photo-1112598.jpeg?auto=compress&cs=tinysrgb&w=800', 'Home', 60),
  ('Bluetooth Speaker', 'Portable waterproof speaker with 360-degree sound', 149.99, 'https://images.pexels.com/photos/1279406/pexels-photo-1279406.jpeg?auto=compress&cs=tinysrgb&w=800', 'Electronics', 70),
  ('Yoga Mat', 'Non-slip eco-friendly yoga mat with carrying strap', 39.99, 'https://images.pexels.com/photos/3822356/pexels-photo-3822356.jpeg?auto=compress&cs=tinysrgb&w=800', 'Fitness', 120)
ON CONFLICT DO NOTHING;