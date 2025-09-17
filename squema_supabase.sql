-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.alimentacion (
  ali_id integer NOT NULL DEFAULT nextval('alimentacion_ali_id_seq'::regclass),
  ali_tipo_alimentacion character varying NOT NULL UNIQUE,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone,
  CONSTRAINT alimentacion_pkey PRIMARY KEY (ali_id)
);
CREATE TABLE public.autorizados (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  num_cedula character varying NOT NULL UNIQUE,
  nombre character varying NOT NULL,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone,
  CONSTRAINT autorizados_pkey PRIMARY KEY (id)
);
CREATE TABLE public.bancos (
  ban_id integer NOT NULL DEFAULT nextval('bancos_ban_id_seq'::regclass),
  ban_banco_nombre character varying NOT NULL UNIQUE,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone,
  CONSTRAINT bancos_pkey PRIMARY KEY (ban_id)
);
CREATE TABLE public.ciudades (
  ciu_id integer NOT NULL DEFAULT nextval('ciudades_ciu_id_seq'::regclass),
  ciu_nombre character varying NOT NULL UNIQUE,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone,
  CONSTRAINT ciudades_pkey PRIMARY KEY (ciu_id)
);
CREATE TABLE public.datos_bancarios (
  dba_id integer NOT NULL DEFAULT nextval('datos_bancarios_dba_id_seq'::regclass),
  dba_num_cuenta character varying NOT NULL,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone,
  dba_banco_id integer NOT NULL,
  CONSTRAINT datos_bancarios_pkey PRIMARY KEY (dba_id),
  CONSTRAINT datos_bancarios_dba_banco_id_fkey FOREIGN KEY (dba_banco_id) REFERENCES public.bancos(ban_id)
);
CREATE TABLE public.epss (
  eps_id integer NOT NULL DEFAULT nextval('epss_eps_id_seq'::regclass),
  eps_nombre character varying NOT NULL UNIQUE,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone,
  CONSTRAINT epss_pkey PRIMARY KEY (eps_id)
);
CREATE TABLE public.generos (
  gen_id integer NOT NULL DEFAULT nextval('generos_gen_id_seq'::regclass),
  gen_nombre character varying NOT NULL UNIQUE,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone,
  CONSTRAINT generos_pkey PRIMARY KEY (gen_id)
);
CREATE TABLE public.perfilamiento (
  perf_id integer NOT NULL DEFAULT nextval('perfilamiento_perf_id_seq'::regclass),
  perf_nombre_perfil character varying NOT NULL UNIQUE,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone,
  CONSTRAINT perfilamiento_pkey PRIMARY KEY (perf_id)
);
CREATE TABLE public.personal (
  per_id integer NOT NULL DEFAULT nextval('personal_per_id_seq'::regclass),
  per_pdf_cedula text,
  per_pdf_rut text,
  per_pdf_comprobante_banco text,
  per_pdf_hoja_vida text,
  per_tipo_doc character varying NOT NULL,
  per_num_doc character varying NOT NULL UNIQUE,
  per_primer_nombre character varying NOT NULL,
  per_segundo_nombre character varying,
  per_primer_apellido character varying NOT NULL,
  per_segundo_apellido character varying,
  per_telefono_llamada character varying,
  per_telefono_whatsapp character varying NOT NULL,
  per_fecha_nacimiento date NOT NULL,
  per_correo character varying NOT NULL,
  per_direccion_residencia character varying NOT NULL,
  per_nombre_emergencia character varying NOT NULL,
  per_telefono_contacto_emergencia character varying NOT NULL,
  per_estatura smallint NOT NULL,
  per_talla_camiseta character varying NOT NULL,
  per_talla_pantalon character varying,
  per_talla_zapatos character varying,
  per_localidad_barrio character varying NOT NULL,
  per_alergias character varying,
  per_nivel_ingles character varying NOT NULL,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone,
  per_genero_id integer NOT NULL,
  per_ciudad_id integer NOT NULL,
  per_eps_id integer,
  per_ali_id integer NOT NULL,
  per_dato_bancario integer NOT NULL,
  per_status_personal integer NOT NULL,
  per_perfilamiento integer NOT NULL,
  per_foto text,
  CONSTRAINT personal_pkey PRIMARY KEY (per_id),
  CONSTRAINT personal_per_genero_id_fkey FOREIGN KEY (per_genero_id) REFERENCES public.generos(gen_id),
  CONSTRAINT personal_per_ciudad_id_fkey FOREIGN KEY (per_ciudad_id) REFERENCES public.ciudades(ciu_id),
  CONSTRAINT personal_per_eps_id_fkey FOREIGN KEY (per_eps_id) REFERENCES public.epss(eps_id),
  CONSTRAINT personal_per_ali_id_fkey FOREIGN KEY (per_ali_id) REFERENCES public.alimentacion(ali_id),
  CONSTRAINT personal_per_dato_bancario_fkey FOREIGN KEY (per_dato_bancario) REFERENCES public.datos_bancarios(dba_id),
  CONSTRAINT personal_per_status_personal_fkey FOREIGN KEY (per_status_personal) REFERENCES public.status_personal(spe_id),
  CONSTRAINT personal_per_perfilamiento_fkey FOREIGN KEY (per_perfilamiento) REFERENCES public.perfilamiento(perf_id)
);
CREATE TABLE public.status_personal (
  spe_id integer NOT NULL DEFAULT nextval('status_personal_spe_id_seq'::regclass),
  spe_status_personal character varying NOT NULL UNIQUE,
  spe_detalle_status character varying,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone,
  CONSTRAINT status_personal_pkey PRIMARY KEY (spe_id)
);