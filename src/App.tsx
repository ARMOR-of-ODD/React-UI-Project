import { useState } from 'react';
import { AuthProvider } from './context/AuthContext';
import { CartProvider } from './context/CartContext';
import { Header } from './components/Header';
import { ProductGrid } from './components/ProductGrid';
import { Cart } from './components/Cart';
import { AuthModal } from './components/AuthModal';
import { Checkout } from './components/Checkout';
import { Orders } from './components/Orders';

function App() {
  const [isCartOpen, setIsCartOpen] = useState(false);
  const [isAuthModalOpen, setIsAuthModalOpen] = useState(false);
  const [isCheckoutOpen, setIsCheckoutOpen] = useState(false);
  const [isOrdersOpen, setIsOrdersOpen] = useState(false);
  const [showSuccessMessage, setShowSuccessMessage] = useState(false);

  const handleCheckout = () => {
    setIsCartOpen(false);
    setIsCheckoutOpen(true);
  };

  const handleCheckoutSuccess = () => {
    setShowSuccessMessage(true);
    setTimeout(() => setShowSuccessMessage(false), 5000);
  };

  return (
    <AuthProvider>
      <CartProvider>
        <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100">
          <Header
            onCartClick={() => setIsCartOpen(true)}
            onAuthClick={() => setIsAuthModalOpen(true)}
            onOrdersClick={() => setIsOrdersOpen(true)}
          />

          <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
            {showSuccessMessage && (
              <div className="mb-6 bg-green-50 border border-green-200 text-green-800 px-6 py-4 rounded-lg">
                <p className="font-semibold">Order placed successfully!</p>
                <p className="text-sm">Thank you for your purchase. Check your order history for details.</p>
              </div>
            )}

            <ProductGrid onAuthRequired={() => setIsAuthModalOpen(true)} />
          </main>

          <Cart
            isOpen={isCartOpen}
            onClose={() => setIsCartOpen(false)}
            onCheckout={handleCheckout}
          />

          <AuthModal
            isOpen={isAuthModalOpen}
            onClose={() => setIsAuthModalOpen(false)}
          />

          <Checkout
            isOpen={isCheckoutOpen}
            onClose={() => setIsCheckoutOpen(false)}
            onSuccess={handleCheckoutSuccess}
          />

          <Orders
            isOpen={isOrdersOpen}
            onClose={() => setIsOrdersOpen(false)}
          />
        </div>
      </CartProvider>
    </AuthProvider>
  );
}

export default App;
