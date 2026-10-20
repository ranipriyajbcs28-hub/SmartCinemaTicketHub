// SMART CINEMA TICKET HUB — Dynamic Seat Selection & Booking Engine

document.addEventListener('DOMContentLoaded', () => {
    const seatGrid = document.getElementById('seatGrid');
    if (!seatGrid) return;

    const basePrice = parseFloat(seatGrid.dataset.ticketPrice || 250);
    const selectedSeatsDisplay = document.getElementById('selectedSeatsText');
    const totalPriceDisplay = document.getElementById('totalPriceText');
    const bookForm = document.getElementById('bookingForm');
    const seatInputsContainer = document.getElementById('seatInputsContainer');
    const checkoutBtn = document.getElementById('checkoutBtn');

    let selectedSeats = new Map(); // seatId -> { number, type, price }
    const MAX_SEATS = 8;

    // Handle seat clicks
    seatGrid.addEventListener('click', (e) => {
        const seatEl = e.target.closest('.seat');
        if (!seatEl || seatEl.classList.contains('booked')) return;

        const seatId = seatEl.dataset.seatId;
        const seatNum = seatEl.dataset.seatNumber;
        const seatType = seatEl.dataset.seatType;

        // Calculate seat price (Balcony +50%, Premium +25%, Regular base)
        let price = basePrice;
        if (seatType === 'Balcony') {
            price = Math.round(basePrice * 1.50);
        } else if (seatType === 'Premium') {
            price = Math.round(basePrice * 1.25);
        }

        if (selectedSeats.has(seatId)) {
            // Deselect seat
            selectedSeats.delete(seatId);
            seatEl.classList.remove('selected');
        } else {
            // Check max seats limit
            if (selectedSeats.size >= MAX_SEATS) {
                alert(`You can select a maximum of ${MAX_SEATS} seats per booking.`);
                return;
            }
            // Select seat
            selectedSeats.set(seatId, { number: seatNum, type: seatType, price: price });
            seatEl.classList.add('selected');
        }

        updateUI();
    });

    function updateUI() {
        if (selectedSeats.size === 0) {
            selectedSeatsDisplay.textContent = 'None';
            totalPriceDisplay.textContent = 'Rs. 0.00';
            if (checkoutBtn) checkoutBtn.disabled = true;
        } else {
            const seatList = Array.from(selectedSeats.values()).map(s => `${s.number} (${s.type})`);
            selectedSeatsDisplay.textContent = seatList.join(', ');

            const total = Array.from(selectedSeats.values()).reduce((sum, s) => sum + s.price, 0);
            totalPriceDisplay.textContent = `Rs. ${total.toFixed(2)}`;
            if (checkoutBtn) checkoutBtn.disabled = false;
        }

        // Sync hidden input fields for the form
        if (seatInputsContainer) {
            seatInputsContainer.innerHTML = '';
            selectedSeats.forEach((_, seatId) => {
                const input = document.createElement('input');
                input.type = 'hidden';
                input.name = 'seat_ids';
                input.value = seatId;
                seatInputsContainer.appendChild(input);
            });
        }
    }

    // Form submit validation
    if (bookForm) {
        bookForm.addEventListener('submit', (e) => {
            if (selectedSeats.size === 0) {
                e.preventDefault();
                alert('Please select at least one seat before proceeding to book.');
            }
        });
    }
});
