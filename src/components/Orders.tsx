import { X, Package } from 'lucide-react';
import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../context/AuthContext';
import { Order, OrderItem } from '../types';

interface OrdersProps {
  isOpen: boolean;
  onClose: () => void;
}

export function Orders({ isOpen, onClose }: OrdersProps) {
  const { user } = useAuth();
  const [orders, setOrders] = useState<Order[]>([]);
  const [orderItems, setOrderItems] = useState<Record<string, OrderItem[]>>({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (isOpen && user) {
      fetchOrders();
    }
  }, [isOpen, user]);

  const fetchOrders = async () => {
    setLoading(true);
    const { data: ordersData, error: ordersError } = await supabase
      .from('orders')
      .select('*')
      .eq('user_id', user?.id)
      .order('created_at', { ascending: false });

    if (!ordersError && ordersData) {
      setOrders(ordersData);

      const itemsPromises = ordersData.map(async (order) => {
        const { data } = await supabase
          .from('order_items')
          .select('*, products(*)')
          .eq('order_id', order.id);
        return { orderId: order.id, items: data || [] };
      });

      const itemsResults = await Promise.all(itemsPromises);
      const itemsMap: Record<string, OrderItem[]> = {};
      itemsResults.forEach(({ orderId, items }) => {
        itemsMap[orderId] = items;
      });
      setOrderItems(itemsMap);
    }
    setLoading(false);
  };

  if (!isOpen) return null;

  return (
    <>
      <div
        className="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4"
        onClick={onClose}
      >
        <div
          className="bg-white rounded-xl shadow-2xl max-w-4xl w-full max-h-[90vh] overflow-hidden flex flex-col"
          onClick={(e) => e.stopPropagation()}
        >
          <div className="flex items-center justify-between p-6 border-b">
            <h2 className="text-2xl font-bold text-gray-900">Order History</h2>
            <button
              onClick={onClose}
              className="text-gray-500 hover:text-gray-700 transition-colors"
            >
              <X className="h-6 w-6" />
            </button>
          </div>

          <div className="flex-1 overflow-y-auto p-6">
            {loading ? (
              <div className="flex justify-center items-center h-64">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
              </div>
            ) : orders.length === 0 ? (
              <div className="flex flex-col items-center justify-center h-64 text-center">
                <Package className="h-16 w-16 text-gray-300 mb-4" />
                <p className="text-gray-500 text-lg mb-2">No orders yet</p>
                <p className="text-gray-400 text-sm">Start shopping to see your orders here!</p>
              </div>
            ) : (
              <div className="space-y-6">
                {orders.map(order => (
                  <div key={order.id} className="border rounded-lg p-6 bg-gray-50">
                    <div className="flex justify-between items-start mb-4">
                      <div>
                        <p className="text-sm text-gray-500">Order ID</p>
                        <p className="font-mono text-sm text-gray-900">{order.id.slice(0, 8)}</p>
                      </div>
                      <div className="text-right">
                        <p className="text-sm text-gray-500">Order Date</p>
                        <p className="text-sm text-gray-900">
                          {new Date(order.created_at).toLocaleDateString()}
                        </p>
                      </div>
                      <div className="text-right">
                        <p className="text-sm text-gray-500">Status</p>
                        <span className="inline-block px-3 py-1 bg-green-100 text-green-800 text-xs font-semibold rounded-full">
                          {order.status}
                        </span>
                      </div>
                    </div>

                    <div className="border-t pt-4 mb-4">
                      <h4 className="font-semibold text-gray-900 mb-3">Items</h4>
                      <div className="space-y-3">
                        {orderItems[order.id]?.map(item => (
                          <div key={item.id} className="flex gap-4 items-center">
                            <img
                              src={item.products?.image_url}
                              alt={item.products?.name}
                              className="w-16 h-16 object-cover rounded"
                            />
                            <div className="flex-1">
                              <p className="font-medium text-gray-900">{item.products?.name}</p>
                              <p className="text-sm text-gray-600">
                                Quantity: {item.quantity} × ${item.price.toFixed(2)}
                              </p>
                            </div>
                            <p className="font-semibold text-gray-900">
                              ${(item.quantity * item.price).toFixed(2)}
                            </p>
                          </div>
                        ))}
                      </div>
                    </div>

                    <div className="border-t pt-4">
                      <div className="flex justify-between items-center">
                        <span className="text-lg font-semibold text-gray-900">Total</span>
                        <span className="text-2xl font-bold text-gray-900">
                          ${order.total_amount.toFixed(2)}
                        </span>
                      </div>
                    </div>

                    <div className="border-t pt-4 mt-4">
                      <h4 className="font-semibold text-gray-900 mb-2">Shipping Address</h4>
                      <div className="text-sm text-gray-600">
                        <p>{order.shipping_address.name}</p>
                        <p>{order.shipping_address.address}</p>
                        <p>
                          {order.shipping_address.city}, {order.shipping_address.state}{' '}
                          {order.shipping_address.zip}
                        </p>
                        <p>{order.shipping_address.country}</p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </>
  );
}
