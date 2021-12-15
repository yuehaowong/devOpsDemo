--
-- postgreSQL database dump
--

-- Dumped from database version 13.4
-- Dumped by pg_dump version 10.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: mmdb; Type: DATABASE; Schema: -; Owner: mmadmin
--

\connect mmdb

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: cards; Type: TABLE; Schema: public; Owner: mmadmin
--

CREATE TABLE cards (
    _id integer NOT NULL,
    market_id integer NOT NULL
);


ALTER TABLE cards OWNER TO mmadmin;

--
-- Name: cards__id_seq; Type: SEQUENCE; Schema: public; Owner: mmadmin
--

CREATE SEQUENCE cards__id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE cards__id_seq OWNER TO mmadmin;

--
-- Name: cards__id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mmadmin
--

ALTER SEQUENCE cards__id_seq OWNED BY cards._id;


--
-- Name: markets; Type: TABLE; Schema: public; Owner: mmadmin
--

CREATE TABLE markets (
    market_id integer NOT NULL,
    location character varying NOT NULL
);


ALTER TABLE markets OWNER TO mmadmin;

--
-- Name: cards _id; Type: DEFAULT; Schema: public; Owner: mmadmin
--

ALTER TABLE ONLY cards ALTER COLUMN _id SET DEFAULT nextval('cards__id_seq'::regclass);


--
-- Name: cards cards_pk; Type: CONSTRAINT; Schema: public; Owner: mmadmin
--

ALTER TABLE ONLY cards
    ADD CONSTRAINT cards_pk PRIMARY KEY (_id);


--
-- Name: markets markets_pk; Type: CONSTRAINT; Schema: public; Owner: mmadmin
--

ALTER TABLE ONLY markets
    ADD CONSTRAINT markets_pk PRIMARY KEY (market_id);


--
-- Name: cards cards_fk0; Type: FK CONSTRAINT; Schema: public; Owner: mmadmin
--

ALTER TABLE ONLY cards
    ADD CONSTRAINT cards_fk0 FOREIGN KEY (market_id) REFERENCES markets(market_id);


--
-- Name: public; Type: ACL; Schema: -; Owner: mmadmin
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM mmadmin;
GRANT ALL ON SCHEMA public TO mmadmin;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- postgreSQL database dump complete
--

