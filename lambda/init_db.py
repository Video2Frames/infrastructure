import logging
import os
import psycopg2

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    """Initializes the PostgreSQL database using SQL scripts"""
    try:
        logger.info("Initializing handler")
        logger.info("Loading environment variables")
        db_host = os.environ["DB_HOST"]
        db_port = os.environ["DB_PORT"]
        db_name = os.environ["DB_NAME"]
        db_user = os.environ["DB_USER"]
        db_password = os.environ["DB_PASSWORD"]
        logger.info("Environment variables loaded")
        logger.info(
            "Connecting to the main database to create databases per application"
        )

        _execute_create_database_sql(
            conn=psycopg2.connect(
                host=db_host,
                port=db_port,
                database=db_name,
                user=db_user,
                password=db_password,
            ),
            file_path="create_status_db.sql"
        )

        _execute_create_database_sql(
            conn=psycopg2.connect(
                host=db_host,
                port=db_port,
                database=db_name,
                user=db_user,
                password=db_password,
            ),
            file_path="create_identification_db.sql"
        )

        logger.info("Creating and initializing application databases")
        _execute_sql_file(
            conn=psycopg2.connect(
                host=db_host,
                port=db_port,
                database="video_status",
                user=db_user,
                password=db_password,
            ),
            file_path="init_status_db.sql"
        )

        _execute_sql_file(
            conn=psycopg2.connect(
                host=db_host,
                port=db_port,
                database="identification",
                user=db_user,
                password=db_password,
            ),
            file_path="init_identification_db.sql"
        )

        return {
            "statusCode": 200,
            "body": "Database initialization completed successfully"
        }

    except Exception as e:
        error_class = e.__class__.__name__
        logger.error(
            "Error initializing database. Exception: %s Message: %s",
            error_class,
            str(e),
            exc_info=True
        )

        return {"statusCode": 500, "body": f"Error initializing database: {str(e)}"}


def _execute_sql_file(conn: psycopg2.extensions.connection, file_path: str):
    logger.info("Database connection established")
    logger.info("Creating cursor")
    cur = conn.cursor()
    logger.info("Cursor created")
    logger.info("Reading %s file", file_path)
    with open(file_path, "r", encoding="utf-8") as file:
        sql_commands = file.read()

    logger.info("%s file loaded", file_path)
    logger.info("Executing SQL commands")
    cur.execute(sql_commands)
    logger.info("SQL commands executed")
    logger.info("Committing changes")
    conn.commit()
    logger.info("Changes committed")
    logger.info("Closing cursor and connection")
    cur.close()
    conn.close()
    logger.info("Cursor and connection closed")
    logger.info("Executed SQL file: %s", file_path)


def _execute_create_database_sql(conn: psycopg2.extensions.connection, file_path: str):
    try:
        conn.autocommit = True
        cur = conn.cursor()
        with open(file_path, "r", encoding="utf-8") as file:
            sql_command = file.read()
        
        logger.info(f"Executing: {sql_command}")
        cur.execute(sql_command)
        logger.info(f"Successfully executed: {file_path}")
        
        cur.close()
        conn.close()
    except psycopg2.errors.DuplicateDatabase as e:
        logger.warning(f"Database already exists: {e}")
        conn.close()
