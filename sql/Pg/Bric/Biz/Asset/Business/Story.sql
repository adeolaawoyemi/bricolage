-- Project: Bricolage
--
-- Target DBMS: PostgreSQL 7.1.2
-- Author: Michael Soderstrom <miraso@pacbell.net>
--
--
-- This is the SQL representation of the story object
--

-- -----------------------------------------------------------------------------
-- Sequences

-- Unique IDs for the story table
CREATE SEQUENCE seq_story START  1024;

-- Unique IDs for the story_instance table
CREATE SEQUENCE seq_story_instance START 1024;

-- Unique IDs for the story__category mapping table
CREATE SEQUENCE seq_story__category START  1024;

-- Unique ids for the story__contributor table
CREATE SEQUENCE seq_story__contributor START 1024;

-- Unique IDs for the story_uri table
CREATE SEQUENCE seq_story_uri START 1024;


-- -----------------------------------------------------------------------------
-- Table: story
--
-- Description: The story properties. Versioning info might get added here and
--              the rights info might get removed. It is also possible that
--              the asset type field will need a cascading delete.


CREATE TABLE story (
    id                INTEGER         NOT NULL
                                      DEFAULT NEXTVAL('seq_story'),
    uuid              TEXT            NOT NULL,
    priority          INT2            NOT NULL
                                      DEFAULT 3
                                      CONSTRAINT ck_story__priority
                                        CHECK (priority BETWEEN 1 AND 5),
    source__id        INTEGER         NOT NULL, 
    usr__id           INTEGER,
    element_type__id  INTEGER         NOT NULL,
    primary_uri       VARCHAR(128),
    first_publish_date TIMESTAMP,
    publish_date      TIMESTAMP,
    expire_date       TIMESTAMP,
    current_version   INTEGER         NOT NULL,
    published_version INTEGER,
    workflow__id      INTEGER         NOT NULL,
    desk__id          INTEGER         NOT NULL,
    publish_status    BOOLEAN         NOT NULL DEFAULT FALSE,
    active            BOOLEAN         NOT NULL DEFAULT TRUE,
    site__id          INTEGER         NOT NULL,
    alias_id          INTEGER         CONSTRAINT ck_story_id
                                        CHECK (alias_id != id),  
    CONSTRAINT pk_story__id PRIMARY KEY (id)
);

-- ----------------------------------------------------------------------------
-- Table story_instance
--
-- Description:  An instance of a story
--

CREATE TABLE story_instance (
    id             INTEGER      NOT NULL
                                DEFAULT NEXTVAL('seq_story_instance'),
    name           VARCHAR(256),
    description    VARCHAR(1024),
    story__id      INTEGER      NOT NULL,
    version        INTEGER,
    usr__id        INTEGER      NOT NULL,
    slug           VARCHAR(64),
    primary_oc__id INTEGER      NOT NULL,
    cover_date     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    note           TEXT,
    checked_out    BOOLEAN      NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_story_instance__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table story_uri
--
-- Description: Tracks all URIs for stories.
--
CREATE TABLE story_uri (
    id        INTEGER     NOT NULL
                              DEFAULT NEXTVAL('seq_story_uri'),
    story__id INTEGER     NOT NULL,
    site__id INTEGER      NOT NULL,
    uri       TEXT            NOT NULL,
    CONSTRAINT pk_story_uri__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table story__output_channel
-- 
-- Description: Mapping Table between stories and output channels.
--
--

CREATE TABLE story__output_channel (
    story_instance__id  INTEGER  NOT NULL,
    output_channel__id  INTEGER  NOT NULL,
    CONSTRAINT pk_story_output_channel
      PRIMARY KEY (story_instance__id, output_channel__id)
);


-- -----------------------------------------------------------------------------
-- Table story__category
-- 
-- Description: Mapping Table between Stories and categories
--
--

CREATE TABLE story__category (
    id                  INTEGER  NOT NULL
                                       DEFAULT NEXTVAL('seq_story__category'),
    story_instance__id  INTEGER  NOT NULL,
    category__id        INTEGER  NOT NULL,
    main                BOOLEAN   NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_story_category__id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Table story__contributor
-- 
-- Description: mapping tables between story instances and contributors
--
--

CREATE TABLE story__contributor (
    id                  INTEGER   NOT NULL
                                        DEFAULT NEXTVAL('seq_story__contributor'),
    story_instance__id  INTEGER   NOT NULL,
    member__id          INTEGER   NOT NULL,
    place               INT2      NOT NULL,
    role                VARCHAR(256),
    CONSTRAINT pk_story_category_id PRIMARY KEY (id)
);

-- -----------------------------------------------------------------------------
-- Indexes.
--

-- story
CREATE INDEX idx_story__uuid ON story(uuid);
CREATE INDEX idx_story__primary_uri ON story(LOWER(primary_uri));
CREATE INDEX fkx_usr__story ON story(usr__id);
CREATE INDEX fkx_source__story ON story(source__id);
CREATE INDEX fkx_element_type__story ON story(element_type__id);
CREATE INDEX fkx_site_id__story ON story(site__id);
CREATE INDEX fkx_alias_id__story ON story(alias_id);
CREATE INDEX idx_story__first_publish_date ON story(first_publish_date);
CREATE INDEX idx_story__publish_date ON story(publish_date);
CREATE INDEX idx_story_instance__cover_date ON story_instance(cover_date);

-- story_instance
CREATE INDEX idx_story_instance__name ON story_instance(LOWER(name));
CREATE INDEX idx_story_instance__description ON story_instance(LOWER(description));
CREATE INDEX idx_story_instance__slug ON story_instance(LOWER(slug));
CREATE UNIQUE INDEX udx_story__story_instance ON story_instance(story__id, version, checked_out);
CREATE INDEX fkx_usr__story_instance ON story_instance(usr__id);
CREATE INDEX fkx_primary_oc__story_instance ON story_instance(primary_oc__id);
CREATE INDEX idx_story_instance__note ON story_instance(note) WHERE note IS NOT NULL;

-- story_uri
CREATE INDEX fkx_story__story_uri ON story_uri(story__id);
CREATE UNIQUE INDEX udx_story_uri__site_id__uri
ON story_uri(lower_text_num(uri, site__id));

-- story__category
CREATE UNIQUE INDEX udx_story_category__story__cat ON story__category(story_instance__id, category__id);
CREATE INDEX fkx_story__story__category ON story__category(story_instance__id);
CREATE INDEX fkx_category__story__category ON story__category(category__id);

-- story__output_channel
CREATE INDEX fkx_story__oc__story ON story__output_channel(story_instance__id);
CREATE INDEX fkx_story__oc__oc ON story__output_channel(output_channel__id);

--story__contributor
CREATE INDEX fkx_story__story__contributor ON story__contributor(story_instance__id);
CREATE INDEX fkx_member__story__contributor ON story__contributor(member__id);

CREATE INDEX fkx_story__desk__id ON story(desk__id) WHERE desk__id > 0;
CREATE INDEX fkx_story__workflow__id ON story(workflow__id) WHERE workflow__id > 0;
