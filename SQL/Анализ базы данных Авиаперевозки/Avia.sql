/*������ 3.1. � ����� ������� ������ ������ ���������?
 * �������: ������� ����� ������� count, ������� �������� �������, � ������� ������ ������ ���������
 * ����� ����������� group by city having count (airport_code) > 1
*/
select count (airport_code), city 
from bookings.airports
group by city 
having count (airport_code) > 1


/*������ 3.2. ���� �� �����, �� ������� �� ����������� ��������?
 * ������ ������ ����� ���������.
 * ������ 1. � ������� �� �������, ��� ���� ��� ��������. 
 * ���������� ������� boarding, tickets � bookings. ��� ����������� boarding � tickets ������������� right join,
 * ����� ������� ������� ������� tickets, ��� ��� ���������� �������� NULL � boarding.
 * ����� ���������� �����������, ������� ������� where boarding_no is null, ����� �������� �����, � ������� ������� ����� �����,
 * �� ����������� boarding_no. �����: ��, ����.
 */
select bp.boarding_no, b.book_ref 
from bookings.boarding_passes bp
	right join bookings.tickets t
	using (ticket_no)
		join bookings.bookings b
		using (book_ref)
where boarding_no is null


/* ������ 3.2. ���� �� �����, �� ������� �� ����������� ��������?
 * ������ 2. �������, ��� ���� ��� �������� ��� �������.
 * ���������� ������� ������� ���������� ������� bookings, tickets, boarding_passes � ticket_flights.
 * ����� ��� ����������� ������������� left join, ��� ��� � ���� ������� ������� bookings ������������ ��� �������,
 * � ��� �������������� ��� ��������� ������� (�� ���������� NULL � ��� �����).
 * ����� ������������� ���� ������ ������ ������� where bp.boarding_no is null
	and f.status in ('Departed', 'Arrived', 'Cancelled'). �����: ���, �� ����.
 */
select b.book_ref, t.ticket_no, bp.boarding_no, f.flight_id, f.status 
from bookings.bookings b
	left join bookings.tickets t
	using (book_ref)
		left join bookings.boarding_passes bp
		using (ticket_no)
			left join bookings.ticket_flights tf
			using (ticket_no)
				left join bookings.flights f
				on f.flight_id = tf.flight_id
where bp.boarding_no is null
and f.status in ('Departed', 'Arrived', 'Cancelled')

	
/* ������ 3.3. � ����� ����������(!) ���� �����, ������� ������������� ���������� � ������������ ���������� ���������?
 * �������: ��� ������� ������ ���������� ������� airports, routes � aircrafts, �������� � ������������ �������� 
 * ���������� �������� airport_code, � ������� �����������, ��� �������� ������� "range" �� ������� aircrafts
 * �������� ������������ ��������� (����� �������������� ����� ���������).
 */
select distinct (a.airport_code), a.airport_name, 
ac.aircraft_code, ac.model, ac."range"
from bookings.airports a
	join bookings.routes r
	on r.departure_airport = a.airport_code
	or r.arrival_airport = a.airport_code
		join bookings.aircrafts ac
		using (aircraft_code)
where ac."range" in (
	select max ("range") 
	from bookings.aircrafts
	)


/* ������ 5*. ����� ������ ��������(!) ��� ������ ������?
(* �������������� ������� ���������� ���������)
 * ��� ������� ������ � ������������ ��������� � ��������� ������������.
 * ����� ���� �������������� ��� �������:  airports (��� ��������� ���� �������)
 * � routes (��� ��������� ���� �������, ����� ������� ���� �����).
 * �������� ��� ������� �� ����������: (���������:
 * ������ ������, � ������� ���������� �������� ������� ����������� � �������� (��� ������) �� ������� airports � ������� �,
 * ���������� ������� airports � ����� ����� � ������� b ����� cross join,
 * ������ �������, ��� ����� �� ������� � �� ����� ������ �� ������� b (��������� ������, 
 * � ������� �� ��������� ����� ����������� � ����� ����������), 
 * �� ���������� ������ ��� ������ except ������ ������ ����:
 * ������������ �������� ������� ������ � �������� �� ������� routes)
 * ��� �������� ����������� ���������� ������. 
 */
select * from ( 
	select a.city|| ' ' ||b.city as city_no_flights 
	from bookings.airports a 
		cross join bookings.airports b 
		where a.city != b.city 
	except 
	select departure_city|| ' ' ||arrival_city 
	from bookings.routes) c 
order by city_no_flights 


/* ������ ��.
 * ������ 1. ������������ �������������������� ������� ���� �������� � �����.
 * ���������� ������� seats � aircrafts. 
 * ��� ������ ������� ������� ������������ ���������� ���� ��� ������� ���� ��������.
 * ��� �������� ������ ��������� �� ���������� ���� � ��������.
 */
select distinct (aircraft_code), a.model,
	count (s.seat_no) over (partition by aircraft_code) as count_seats
from bookings.seats s
	join bookings.aircrafts a
	using (aircraft_code)
order by count_seats desc


/* ������ 2.1. ������� ����� ���������-����������� ������, ����� ������ �������� ��� ����������� � ���� ������.
 * ���� ������ ��������� ��� ����, ����� ������� � �� ��������, ������� ��� � �������.
 * ��������� ��� �����, ���� �� ������� ������� �����, ��� ��� ���� ���������� ��� ���������� ��������.
 * ������� ������������ �������, ������ ���� ���������� ���������� ������
 * � ��������� count ������ ���������� ��������� ������� �� ���������� flight_id,
 * ��������� ������� ticket_flights, flights_v � aircraft_code
 * �������� �� count_tickets 
 */
select distinct (flight_id), 
f.departure_city|| ' '|| f.arrival_city as cities, f.actual_departure, 
a.aircraft_code, a.model, 
count (ticket_no) over (partition by flight_id) as count_tickets
from bookings.ticket_flights
	join bookings.flights_v f
	using (flight_id)
		join bookings.aircrafts a
		using (aircraft_code) 
order by count_tickets desc

/* ������ 2.2. ������� ����� ���������-����������� ����� (������ 5000 �������), ����� ������ �������� ��� �����������.
 * ����� ��� ���� �� ���������� ���������� ������, � ���������� ����� � ���������� ����������.
 * ��� ��� ������ � ������� � ���� �� ����� �� ���� � ����� �����, �� �� ������� � ����� ���������� ���������� �� ����� ���� ��������������� ������.
 * ����� �� ����������� ������� � ������ ������ ������� � ����� ������ 
 * � ������������ ��� � �������� ��������� ������, �� ���� ������������ ��������� � ������ �������, 
 * �������� ������, � ������� ������� ������� ����� �������� ����� 5000, ������������� �� �����������.
 */
select * from (
	select distinct (flight_no), f.departure_city|| ' '|| f.arrival_city as cities, 
	a.aircraft_code, a.model, 
	count (ticket_no) over (partition by flight_no) as count_tickets
	from bookings.ticket_flights
		join bookings.flights_v f
		using (flight_id)
			join bookings.aircrafts a
			using (aircraft_code) 
	) z
where count_tickets > 5000
order by count_tickets desc

/* ������ 3.1. ������� ������, ����� ������ �������� ��� ��������������, ������ ��������, �������������� ����, ���������� ���� � ��������
 * � ������� �������� �������� ����������� (����� 95%).
 * ������� ������� � flight_id, ��������, ����� ������� ������������� ����, ����������� ���� � ��������, ����������� ��������� ������� � 
 * ������� �������� �� ������� (round((z.count_tickets * 100 / z.aircraft_seats), 2).
 * � ���������� ������ �������� ������ - ���������� flight_id, ������� ��������� ������, ��������������� ��� ������ ������� ������� �� flight_id,
 * ��� ������ ��������� case � �������� �������� aircraft_code �� �������� (���������� ���� � ��������),
 * �������� ������� ������ � 1. ������� ��� ���� ������, ��� �� ������� ����� ������������ ������ � �������������� 
 * ������� seats. ���������� ������� ticket_flights, flights_v � aircrafts,
 * ������ ������� where z.count_tickets * 100 / z.aircraft_seats > 95 � ���������� �� ��������.
 * ������� where z.count_tickets * 100 / z.aircraft_seats > 95 ����� ���� �� ��������� ����� ��� ���� ���������, �� ����� ��� � ������ ������������.
 */
select flight_id, z.cities, z.model, z.aircraft_seats, z.count_tickets,
round ((z.count_tickets * 100 / z.aircraft_seats), 2) as percent_seats
from (	
	select distinct (flight_id), f.departure_city||' '||f.arrival_city as cities, a.model, 
		case 
		when a.aircraft_code = '773' then 402
		when a.aircraft_code = '763' then 222
		when a.aircraft_code = '321' then 170
		when a.aircraft_code = '320' then 140
		when a.aircraft_code = '733' then 130
		when a.aircraft_code = '319' then 116
		when a.aircraft_code = 'SU9' then 97
		when a.aircraft_code = 'CR2' then 50
		when a.aircraft_code = 'CN1' then 12
		end as aircraft_seats,
	count (ticket_no) over (partition by flight_id) as count_tickets
	from bookings.ticket_flights
		join bookings.flights_v f
		using (flight_id)
			join bookings.aircrafts a
			using (aircraft_code) 
	) z
where z.count_tickets * 100 / z.aircraft_seats > 95
order by model desc

/* ������ 3.2 ��������� �� ���� ����������� ������� ������� ������ ��������� ������ ����� ���������.
  */
select model, count (flight_id) as count_flights from (
select flight_id, z.cities, z.model, z.aircraft_seats, z.count_tickets,
round ((z.count_tickets * 100 / z.aircraft_seats), 2) as percent_seats
from (	
	select distinct (flight_id), f.departure_city||' '||f.arrival_city as cities, a.model, 
		case 
		when a.aircraft_code = '773' then 402
		when a.aircraft_code = '763' then 222
		when a.aircraft_code = '321' then 170
		when a.aircraft_code = '320' then 140
		when a.aircraft_code = '733' then 130
		when a.aircraft_code = '319' then 116
		when a.aircraft_code = 'SU9' then 97
		when a.aircraft_code = 'CR2' then 50
		when a.aircraft_code = 'CN1' then 12
		end as aircraft_seats,
	count (ticket_no) over (partition by flight_id) as count_tickets
	from bookings.ticket_flights
		join bookings.flights_v f
		using (flight_id)
			join bookings.aircrafts a
			using (aircraft_code) 
	) z
where z.count_tickets * 100 / z.aircraft_seats > 95
order by model desc) y
group by model
order by count_flights 


/* ������ 4.1. ������� ����� ���������� ����� (������ 100 000 000 ������ �� �����), ����� ������ �������� ��� ��������������, 
 * ����� ������� �� ������� ����� � ���������� ����������. ��������� ��� �����, ���� ���� �� �����������, �� ���� � ������� �������� �������.
 * ������� ������� � ������� ����� � �������� ������ � ��������, �������� ������� ������� ����� �� ��������� �������
 * � ���������� ��������� �������. 
 * ���������� ������� flights_v, ticket_flights, ���������� ������ �� ������� flight_no, 
 * ��� ������� ����� ����� �������� ������ 100 000 000 ������. ��������� �� �����.
 */
select flight_no, departure_city, arrival_city,  
sum (t.amount) as total_amount, 
count (t.ticket_no) as total_number_of_passenger
from bookings.flights_v f
	join bookings.ticket_flights t
	using (flight_id)
		group by flight_no, departure_city, arrival_city
		having sum (t.amount) > 100000000
order by total_amount desc

/*������ 4.2 ������� ����� ���������� ����� (������ 100 000 000 ������ �� �����), ����� ������ �������� ��� ��������������, 
 * ����� ������� �� ������� ����� � ���������� ����������. 
 * ��������� ������ ��� ����������� �����, ����� ������� �� ��������� ������ ����� �������� �������.
 * ������� ����� ����� ��, ������ ��������� �������, ��� ������ ������� "�������" � "������".
 */
select flight_no, departure_city, arrival_city,  
sum (t.amount) as total_amount, 
count (t.ticket_no) as total_number_of_passenger
from bookings.flights_v f
	join bookings.ticket_flights t
	using (flight_id)
		where f.status in ('Departed', 'Arrived')
			group by flight_no, departure_city, arrival_city
			having sum (t.amount) > 100000000
order by total_amount desc


/* ������ 5.1. ������� ����� ������������, �������� ��������� ����� � ��������� ������ 100 ���������� �� ����� � �������� ������ 5 000 000 ������,
 *  ������� ��������� ������, ���������� ��������� ������� �� ����� � ����� ����� ��������� �������, 
 * ������ ������� ������� ������� "� ������", "������", "�������" � "������ ��� �����������",
 * ����� ����� ������, ��� ������� � ����� CN1 (Cessna 208 Caravan) ����� ����������� 12 �������, ������� �������� ��� �� �������.
 * ������� ������� � ������� �����, ������� ���������� ������, ����������� �� ���� �������, ����� ��������� �������
 * � ���������� ��������� ������� �� ������������ ������ ticket_flights, flights_v � aircrafts. 
 * ��� ������ WHERE ��������������� �������� � ����� CN1 (Cessna 208 Caravan) � �������� ������� ('Departed', 'Arrived', 'Delayed', 'Cancelled')
 * ��� ��� ����������� � ���������, ����� ������� ����� ������ where count_ticket < 100 � sum_amount < 5000000. ��������� �� �����.
 */
select * from (
	select f.flight_no, f.departure_city|| ' '||f.arrival_city as cities, 
	round (avg (amount), 2) as avg_amount, 
	sum (amount) as sum_amount, 
	count (ticket_no) as count_ticket
	from bookings.ticket_flights
		join bookings.flights_v f
		using (flight_id)
			join bookings.aircrafts a
			using (aircraft_code)
	where a.aircraft_code not in ('CN1')
	and f.status in ('Departed', 'Arrived', 'Delayed', 'Cancelled')
		group by f.flight_no, f.departure_city, f.arrival_city
	) z
where count_ticket < 100
and sum_amount < 5000000
order by sum_amount

/* ������ 5.2 ������� ���������� �� ����������� �����.
 * 
 */
select flight_id, flight_no, aircraft_code, actual_departure 
from bookings.flights_v
where flight_no = 'PG0587'
and actual_departure is not null
order by actual_departure

--� �������� ����
select flight_id, flight_no, aircraft_code, actual_departure 
from bookings.flights_v
where flight_no = 'PG0587'
and actual_departure is not null
order by actual_departure


/* ������ 6. ������� ����������� �������� ������ ��� ������� ������ ������������.
 * ��������� ������� �� ������� ticket_flights ��� ������ ������� min (amount) � max (amount). 
 * ����������� �� ������ ������������.
 */
select fare_conditions, 
min (amount) as min_amount 
from bookings.ticket_flights
group by fare_conditions

