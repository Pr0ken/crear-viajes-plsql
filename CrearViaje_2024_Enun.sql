
drop table modelos cascade constraints;
drop table autocares cascade constraints;
drop table recorridos cascade constraints;
drop table viajes cascade constraints;
drop table tickets cascade constraints;

create table modelos(
 idModelo integer primary key,
 nplazas integer
);

create table autocares(
  idAutocar   integer primary key,
  modelo      integer references modelos,
  kms         integer not null
);

create table recorridos(
   idRecorrido      integer primary key,
   estacionOrigen   varchar(15) not null,
   estacionDestino  varchar(15) not null,
   kms              numeric(6,2) not null,
   precio           numeric(5,2) not null
);

create table viajes(
 idViaje     	integer primary key,
 idAutocar   	integer references autocares  not null,
 idRecorrido 	integer references recorridos not null,
 fecha 		    date not null,
 nPlazasLibres	integer not null,
 Conductor    varchar(25) not null,
 unique (idRecorrido, fecha) 
);

drop sequence seq_viajes;
create sequence seq_viajes;

create table tickets(
 idTicket 	integer primary key,
 idViaje  	integer references viajes not null,
 fechaCompra    date not null,
 cantidad       integer not null,
 precio		numeric(5,2) not null
);
drop sequence seq_tickets;
create sequence seq_tickets;

insert into modelos (idModelo, nPlazas) values ( 1, 40 );  
insert into modelos (idModelo, nPlazas) values ( 2, 15 );  
insert into modelos (idModelo, nPlazas) values ( 3, 35 );  

insert into autocares ( idAutocar, modelo, kms) values (1, 1, 1000);
insert into autocares ( idAutocar, modelo, kms) values (2, 1, 7500);
insert into autocares ( idAutocar, modelo, kms) values (3, 2, 2000);
insert into autocares ( idAutocar, kms) values (4, 1000);

insert into recorridos (idRecorrido, estacionOrigen, estacionDestino, kms, precio)
values (1, 'Burgos', 'Madrid', 201, 10 );
insert into recorridos (idRecorrido, estacionOrigen, estacionDestino, kms, precio)
values (2, 'Burgos', 'Madrid', 200, 12);
insert into recorridos (idRecorrido, estacionOrigen, estacionDestino, kms, precio)
values (3, 'Madrid', 'Burgos', 200, 10);
insert into recorridos (idRecorrido, estacionOrigen, estacionDestino, kms, precio)
values (4, 'Leon', 'Zamora', 150, 6);

insert into viajes (idViaje, idAutocar, idRecorrido, fecha, nPlazasLibres,  Conductor)
values (seq_viajes.nextval, 1, 1, DATE '2009-1-22', 30, 'Juan');
insert into viajes (idViaje, idAutocar, idRecorrido, fecha, nPlazasLibres,  Conductor)
values (seq_viajes.nextval, 1, 1, trunc(current_date)+1, 38, 'Javier');
insert into viajes (idViaje, idAutocar, idRecorrido, fecha, nPlazasLibres,  Conductor)
values (seq_viajes.nextval, 1, 1, trunc(current_date)+7, 10, 'Maria');
insert into viajes (idViaje, idAutocar, idRecorrido, fecha, nPlazasLibres,  Conductor)
values(seq_viajes.nextval, 2, 4, trunc(current_date)+7, 40, 'Ana');


commit;
--exit;


create or replace procedure crearViaje (
    m_idRecorrido int, 
    m_idAutocar int, 
    m_fecha date, 
    m_conductor varchar
) is
    v_modelo integer;
    v_plazas_libres integer;
    v_autocar_ocupado integer;
    v_viaje_duplicado integer;
    v_autocar_sin_modelo integer;
begin
    -- Verificar si el recorrido existe
    select count(*) into v_modelo from recorridos where idRecorrido = m_idRecorrido;
    if v_modelo = 0 then
        raise_application_error(-20001, 'RECORRIDO_INEXISTENTE');
    end if;

    -- Verificar si el autocar existe
    select count(*) into v_modelo from autocares where idAutocar = m_idAutocar;
    if v_modelo = 0 then
        raise_application_error(-20002, 'AUTOCAR_INEXISTENTE');
    end if;

    -- Verificar si el autocar está ocupado para la fecha especificada
    select count(*) into v_autocar_ocupado from viajes where idAutocar = m_idAutocar and fecha = m_fecha;
    if v_autocar_ocupado > 0 then
        raise_application_error(-20003, 'AUTOCAR_OCUPADO');
    end if;

    -- Verificar si ya existe un viaje para ese autocar y recorrido en la misma fecha
    select count(*) into v_viaje_duplicado from viajes where idAutocar = m_idAutocar and idRecorrido = m_idRecorrido and fecha = m_fecha;
    if v_viaje_duplicado > 0 then
        raise_application_error(-20004, 'VIAJE_DUPLICADO');
    end if;

    -- Obtener la cantidad de plazas libres para el autocar
    select nPlazasLibres into v_plazas_libres from viajes where idAutocar = m_idAutocar and fecha = m_fecha;
    
    -- Si el autocar no tiene modelo asociado, se tomarán 25 plazas libres por defecto
    if v_plazas_libres is null then
        v_plazas_libres := 25;
    end if;

    -- Insertar el nuevo viaje
    insert into viajes (idViaje, idAutocar, idRecorrido, fecha, nPlazasLibres, Conductor)
    values (seq_viajes.nextval, m_idAutocar, m_idRecorrido, m_fecha, v_plazas_libres, m_conductor);
    
    commit;
end;
/

set serveroutput on


create or replace procedure test_crearViaje is
begin
  
  --Caso 1: RECORRIDO_INEXISTENTE
  begin
    crearViaje(11, 2, trunc(current_date), 'Juanito');
    dbms_output.put_line('Mal no detecta RECORRIDO_INEXISTENTE');
  exception
    when others then
      if sqlcode = -20001 then
        dbms_output.put_line('OK: Detecta RECORRIDO_INEXISTENTE: '||sqlerrm);
      else
        dbms_output.put_line('Mal no detecta RECORRIDO_INEXISTENTE: '||sqlerrm);
      end if;
  end;
  
  
  --Caso 2: AUTOCAR_INEXISTENTE
   begin
    crearViaje(1, 22, trunc(current_date), 'Juanito');
    dbms_output.put_line('Mal no detecta AUTOCAR_INEXISTENTE');
  exception
    when others then
      if sqlcode = -20002 then
        dbms_output.put_line('OK: Detecta AUTOCAR_INEXISTENTE: '||sqlerrm);
      else
        dbms_output.put_line('Mal no detecta AUTOCAR_INEXISTENTE: '||sqlerrm);
      end if;
  end;
  
  
  --Caso 3: AUTOCAR_OCUPADO
   begin
    crearViaje(2, 1, trunc(current_date)+1, 'Juanito');
    dbms_output.put_line('Mal no detecta AUTOCAR_OCUPADO');
  exception
    when others then
      if sqlcode = -20003 then
        dbms_output.put_line('OK: Detecta AUTOCAR_OCUPADO: '||sqlerrm);
      else
        dbms_output.put_line('Mal no detecta AUTOCAR_OCUPADO: '||sqlerrm);
      end if;
  end;
  
  
  --Caso 4: VIAJE_DUPLICADO
   begin
    crearViaje(1, 2, trunc(current_date)+1, 'Juanito');
    dbms_output.put_line('Mal no detecta VIAJE_DUPLICADO');
  exception
    when others then
      if sqlcode = -20004 then
        dbms_output.put_line('OK: Detecta VIAJE_DUPLICADO: '||sqlerrm);
      else
        dbms_output.put_line('Mal no detecta VIAJE_DUPLICADO: '||sqlerrm);
      end if;
  end;
  
  
  --Caso 4: Crea un viaje OK
  begin
    crearViaje(1, 1, trunc(current_date)+3, 'Pedrito');
    dbms_output.put_line('Parece OK Crea un viaje v�lido');
  exception
    when others then
        dbms_output.put_line('MAL Crea un viaje v�lido: '||sqlerrm);
  end;
  
  
  --Caso 5: Crea un viaje OK con autcar sin modelo
  begin
    crearViaje(1, 4, trunc(current_date)+4, 'Jorgito');
    dbms_output.put_line('Parece OK Crea un viaje v�lido sin modelo');
  exception
    when others then
        dbms_output.put_line('MAL Crea un viaje v�lido sin modelo: '||sqlerrm);
  end;
  
  
  --Caso FINAL: Todo OK
  declare
    varContenidoReal varchar(500);
    varContenidoEsperado    varchar(500):= 
      '11122/01/0930Juan#211' || to_char(trunc(current_date)+1,'DD/MM/YY') || '38Javier#311' || to_char(trunc(current_date)+7,'DD/MM/YY') || '10Maria#424' || to_char(trunc(current_date)+7,'DD/MM/YY') || '40Ana#511' || to_char(trunc(current_date)+3,'DD/MM/YY') || '40Pedrito#641' || to_char(trunc(current_date)+4,'DD/MM/YY') || '25Jorgito';
    
  begin
    rollback; --por si se olvida commit de matricular
    
    SELECT listagg( idViaje || idAutocar || idRecorrido || fecha || nPlazasLibres || Conductor, '#')
        within group (order by idViaje)
    into varContenidoReal
    FROM viajes;
    
    if varContenidoReal=varContenidoEsperado then
      dbms_output.put_line('OK: S� que modifica bien la BD.'); 
    else
      dbms_output.put_line('Mal no modifica bien la BD.'); 
      dbms_output.put_line('Contenido real:     '||varContenidoReal); 
      dbms_output.put_line('Contenido esperado: '||varContenidoEsperado); 
    end if;
    
  exception
    when others then
      dbms_output.put_line('Mal caso todo OK: '||sqlerrm);
  end;
  
end;
/

begin
  test_crearViaje;
end;
/

